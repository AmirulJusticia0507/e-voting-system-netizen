"""V7-A: Paket share & bahan QR untuk setiap Topik (hasil publik yang bisa
dibagikan ke WhatsApp/IG/Telegram/web tanpa login)."""
from django.conf import settings


def share_url(topic_id):
    """Link publik untuk sebuah topik; dipakai untuk QR & tombol share."""
    base = settings.PUBLIC_BASE_URL.rstrip("/")
    return f"{base}/vote/{topic_id}/"


def topic_share_bundle(topic_id, request=None):
    """Susun payload share ringkas:
    - share_url   : link publik (dibuka tanpa login)
    - share_text  : teks siap-tempel (untuk WA/IG/Telegram)
    - data        : ringkasan hasil & partisipasi (ringan, tanpa detail per-suara)
    """
    from .results import topic_results, topic_evidence
    from topics.models import Topic

    topic = Topic.objects.filter(pk=topic_id).first()
    if not topic:
        return None

    ev = topic_evidence(topic_id)
    results = topic_results(topic_id)

    candidates = ev.get("candidates", []) or []
    # urut: terbanyak di atas; sertakan pct
    candidates = sorted(
        ({**c, "percent": _percent(c.get("votes"), ev.get("total_votes", 0))} for c in candidates),
        key=lambda c: c.get("votes", 0),
        reverse=True,
    )

    leader = candidates[0]["candidate_name"] if candidates else "Belum ada"
    leader_pct = candidates[0]["percent"] if candidates else 0
    root = ev.get("evidence_root") or results.get("evidence_root") or "-"
    text = (
        f"🗳️ {topic.title}\n"
        f"Memimpin sementara: {leader} ({leader_pct}%) "
        f"dari {ev.get('total_votes', 0)} suara.\n"
        f"Bukti: {root}\n"
        f"Lihat hasil: {share_url(topic_id)}"
    )

    return {
        "topic_id": topic_id,
        "topic_title": topic.title,
        "share_url": share_url(topic_id),
        "share_text": text,
        "total_votes": ev.get("total_votes", 0),
        "evidence_root": ev.get("evidence_root", ""),
        "participation_percent": results.get("participation_percent"),
        "candidates": candidates,
    }


def _percent(n, total):
    return round((n * 100.0 / total), 1) if total else 0.0