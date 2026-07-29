from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from django.db.models import Count, Sum
from .models import Vote
from .serializers import VoteSerializer

from users.models import User

from .services import send_whatsapp_vote_notification

class VoteViewSet(viewsets.ModelViewSet):
    serializer_class = VoteSerializer

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

        topic = serializer.validated_data["topic"]
        if Vote.objects.filter(user=user, topic=topic).exists():
            raise ValidationError("User sudah memilih pada topik ini.")

        vote = serializer.save(user=user)
        # 📲 Kirim notifikasi bukti vote ke WhatsApp voters
        try:
            send_whatsapp_vote_notification(vote)
        except Exception as e:
            print(f"Gagal memicu WhatsApp notification: {e}")



    # 🔹 Custom action untuk rekap hasil per kandidat
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
