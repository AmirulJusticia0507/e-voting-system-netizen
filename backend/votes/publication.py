"""V7-C: Lapisan publik/arsip — hub periode, arsip periode terverifikasi, dan
rekap global yang bisa diverifikasi tanpa login (trust/transparansi)."""
from django.utils import timezone
from election.models import ElectionPeriod


def public_hub():
    """Daftar periode pemilihan + topik beserta evidence_root & total suara.
    Bisa ditampilkan tanpa login sebagai "papan nama" publik."""
    from topics.models import Topic
    from .results import topic_evidence
    from django.db.models import Count

    periods = []
    for election in ElectionPeriod.objects.all().order_by("-start_at"):
        topics = Topic.objects.filter(election=election)
        topic_rows = []
        for t in topics:
            ev = topic_evidence(t.id)
            topic_rows.append({
                "topic_id": ev.get("topic_id"),
                "title": ev.get("topic_title"),
                "total_votes": ev.get("total_votes", 0),
                "evidence_root": ev.get("evidence_root", ""),
            })
        reg_count = election.voters.filter(is_active=True).count()
        periods.append({
            "election_id": election.id,
            "name": election.name,
            "description": election.description,
            "status": "ongoing" if election.ongoing else ("upcoming" if not election.has_started else "closed"),
            "start_at": election.start_at.isoformat(),
            "end_at": election.end_at.isoformat(),
            "dpt": reg_count,
            "total_votes": sum(t["total_votes"] for t in topic_rows),
            "topics": topic_rows,
        })
    return periods


def election_archive(election_id):
    """Arsip GREG untuk satu periode: per-topik hasil + bukti, ditandatangani."""
    from topics.models import Topic
    from .results import topic_results, topic_evidence
    from . import signature

    election = ElectionPeriod.objects.filter(pk=election_id).first()
    if not election:
        return None

    topics = []
    for t in Topic.objects.filter(election=election):
        res = topic_results(t.id)
        ev = topic_evidence(t.id)
        topics.append({
            "topic_id": t.id,
            "title": t.title,
            "total_votes": res.get("total_votes", 0),
            "participation_percent": res.get("participation_percent"),
            "evidence_root": ev.get("evidence_root", ""),
            "candidates": res.get("candidates", []),
        })

    manifest = {
        "type": "election_archive",
        "election_id": election.id,
        "election_name": election.name,
        "generated_at": timezone.now().isoformat(),
        "start_at": election.start_at.isoformat(),
        "end_at": election.end_at.isoformat(),
        "topics": topics,
    }
    return {
        "election": {
            "id": election.id,
            "name": election.name,
            "status": "ongoing" if election.ongoing else ("closed" if not election.has_started else "upcoming"),
        },
        "manifest_hash": signature.manifest_hash(manifest),
        "signature": signature.sign(manifest),
        "public_key": signature.public_key_hex(),
        "algorithm": "ed25519",
        "data": manifest,
    }