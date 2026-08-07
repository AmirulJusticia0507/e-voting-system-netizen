from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import SAFE_METHODS
from django.db.models import Count, Sum
from django.conf import settings
from .models import Vote
from .serializers import VoteSerializer
from . import crypto
from users.models import User
from .services import send_whatsapp_vote_notification
from roles.permissions import (
    IsNetizenVoter,
    HasPermission,
)


def _eligibility_error(user, topic):
    """Return pesan error string bila user belum eligible; None jika boleh memilih."""
    from django.utils import timezone
    from election.models import VoterRegistration

    election = topic.election
    if not election:
        return None  # topik legacy tanpa periode → tetap memperbolehkan (backward compat)
    if not election.is_active:
        return "Periode pemilihan nonaktif."
    now = timezone.now()
    if now < election.start_at:
        return "Periode pemilihan belum dibuka."
    if now > election.end_at:
        return "Periode pemilihan sudah selesai."

    # DPT: harus terdaftar & aktif pada periode ini
    reg = VoterRegistration.objects.filter(user=user, election=election).first()
    if not reg or not reg.is_active:
        return "Nomor Anda belum terdaftar pada DPT periode ini."

    # Wilayah: region topik harus sama dengan region registrasi (jika ada)
    if topic.region and reg.region and topic.region_id != reg.region_id:
        return "Anda hanya dapat memilih pada wilayah terdaftar Anda."
    return None


def _secret():
    return settings.VOTE_ENCRYPTION_KEY


class VoteViewSet(viewsets.ModelViewSet):
    serializer_class = VoteSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return [HasPermission()]
        return [IsNetizenVoter()]

    def get_queryset(self):
        queryset = Vote.objects.all()
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset

    def perform_create(self, serializer):
        user = serializer.validated_data.get("user")
        if not user:
            user = self.request.user if self.request.user.is_authenticated else User.objects.first()
            if not user:
                raise ValidationError("Pengguna tidak ditemukan.")

        # V2: hanya pemilih yang sudah diverifikasi OTP boleh memilih
        if not user.is_verified:
            raise ValidationError(
                "Akun belum diverifikasi. Silakan verifikasi OTP dulu "
                "lewat POST /api/auth/otp/request/ & /api/auth/otp/verify/."
            )

        topic = serializer.validated_data["topic"]
        if Vote.objects.filter(user=user, topic=topic).exists():
            raise ValidationError("User sudah memilih pada topik ini.")

        # V3: cek periode pemilihan & DPT & wilayah
        eligibility_error = _eligibility_error(user, topic)
        if eligibility_error:
            raise ValidationError(eligibility_error)

        candidate = serializer.validated_data["candidate"]

        # ---- Lapis integritas (anti-tamper) ----
        last = Vote.objects.order_by("-id").first()
        previous_hash = last.integrity_hash if last else "GENESIS"
        nonce = crypto.token_hex(16)
        integrity_hash = crypto.compute_vote_hash(previous_hash, candidate.id, nonce, _secret())
        encrypted_choice = crypto.encrypt(str(candidate.id), _secret())

        vote = serializer.save(
            user=user,
            previous_hash=previous_hash,
            integrity_hash=integrity_hash,
            nonce=nonce,
            encrypted_choice=encrypted_choice,
        )

        from audit.services import record

        record(
            "vote.cast",
            actor=user,
            target_type="vote",
            target_pk=vote.id,
            request=self.request,
            detail={
                "topic": topic.id,
                "candidate": candidate.id,
                "integrity_hash": integrity_hash,
            },
        )

        # 📲 Kirim notifikasi bukti vote ke WhatsApp voters
        try:
            send_whatsapp_vote_notification(vote)
        except Exception as e:
            print(f"Gagal memicu WhatsApp notification: {e}")


    # 🔹 Rekap resmi (Ci.Cii) dengan tanda tangan digital
    @action(detail=False, methods=["get"])
    def recap(self, request):
        from django.utils import timezone
        from .results import recap as recap_data
        from . import signature

        elections = recap_data()
        manifest = {
            "type": "ci-cii_recap",
            "generated_at": timezone.now().isoformat(),
            "elections": elections,
        }
        return Response({
            "manifest_hash": signature.manifest_hash(manifest),
            "signature": signature.sign(manifest),
            "public_key": signature.public_key_hex(),
            "signature_algorithm": "ed25519",
            "data": manifest,
        })

    @action(detail=False, methods=["post"])
    def recap_verify(self, request):
        """POST {signature, public_key, data} → {valid: bool}"""
        from . import signature

        data = request.data.get("data")
        sig = request.data.get("signature")
        pub = request.data.get("public_key")
        if not all([data, sig, pub]):
            return Response(
                {"valid": False, "detail": "data, signature, public_key wajib ada."},
                status=400,
            )
        ok = signature.verify(data, str(sig), str(pub))
        return Response({"valid": ok})

    # 🔹 Rekap & partisipasi semua topik (bahan snapshot live)
    @action(detail=False, methods=["get"])
    def stats(self, request):
        from .results import all_results

        data = all_results()
        total_votes = sum(t.get("total_votes", 0) for t in data if "total_votes" in t)
        return Response({"total_votes": total_votes, "topics": data})

    # 🔹 Bukti ringkas transparan (aggregate root hash, tanpa detail per-suara)
    @action(detail=False, methods=["get"])
    def evidence(self, request):
        from .results import all_evidence

        return Response({"evidence": all_evidence()})


    # 🔹 Rantai hash seluruh suara (bukti integritas)
    @action(detail=False, methods=["get"])
    def chain(self, request):
        votes = Vote.objects.order_by("id")
        items = []
        prev = "GENESIS"
        valid_chain = True
        for v in votes:
            expected = crypto.compute_vote_hash(prev, v.candidate_id, v.nonce, _secret())
            link_ok = (v.previous_hash == prev) and (expected == v.integrity_hash)
            if not link_ok:
                valid_chain = False
            items.append({
                "id": v.id,
                "topic": v.topic_id,
                "candidate": v.candidate_id,
                "previous_hash": v.previous_hash,
                "integrity_hash": v.integrity_hash,
                "link_valid": link_ok,
            })
            prev = v.integrity_hash
        return Response({
            "total": len(items),
            "chain_valid": valid_chain,
            "votes": items,
        })


    # 🔹 Verifikasi satu suara (hash & dekripsi konsisten?)
    @action(detail=True, methods=["post"])
    def verify(self, request, pk=None):
        vote = self.get_object()
        if not vote.verifiable:
            return Response({
                "id": vote.id,
                "valid": False,
                "reason": "vote_missing_integrity_fields",
            })
        try:
            decrypted = crypto.decrypt(vote.encrypted_choice, _secret())
            decrypted_ok = (decrypted == str(vote.candidate_id))
        except Exception:
            decrypted_ok = False

        expected = crypto.compute_vote_hash(vote.previous_hash, vote.candidate_id, vote.nonce, _secret())
        hash_ok = (expected == vote.integrity_hash)

        return Response({
            "id": vote.id,
            "valid": hash_ok and decrypted_ok,
            "hash_valid": hash_ok,
            "decrypted_choice_valid": decrypted_ok,
            "decrypted_candidate": decrypted if decrypted_ok else None,
        })


    # 🔹 Custom action untuk rekap hasil per kandidat (bisa dilihat voter & admin)
    @action(detail=False, methods=["get"], url_path="results")
    def results(self, request):
        results = (
            Vote.objects
            .values("topic__id", "topic__title", "candidate__id", "candidate__name")
            .annotate(
                vote_count=Count("id"),
                likes=Sum("candidate__comments__likes"),
                dislikes=Sum("candidate__comments__dislikes")
            )
            .order_by("topic__id", "-vote_count")
        )

        formatted = {}
        for r in results:
            topic_id = r["topic__id"]
            topic_title = r["topic__title"]
            if topic_id not in formatted:
                formatted[topic_id] = {
                    "topic_id": topic_id,
                    "topic_title": topic_title,
                    "candidates": []
                }
            formatted[topic_id]["candidates"].append({
                "candidate_id": r["candidate__id"],
                "candidate_name": r["candidate__name"],
                "vote_count": r["vote_count"],
                "likes": r["likes"] or 0,
                "dislikes": r["dislikes"] or 0
            })

        return Response(list(formatted.values()))