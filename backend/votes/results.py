"""Agregasi hasil & partisipasi yang dipakai REST dan WebSocket (real-time)."""
from django.db.models import Count
from django.utils import timezone
from election.models import VoterRegistration


def topic_results(topic_id, candidate_id=None):
    """Hasil untuk satu topik: per-kandidat + total + partisipasi (berbasis DPT)."""
    from .models import Vote
    from candidates.models import Candidate
    from topics.models import Topic

    topic = Topic.objects.filter(pk=topic_id).first()
    if not topic:
        return {"error": "topic_not_found"}

    todos_votes = Vote.objects.filter(topic_id=topic_id)
    counts = (
        todos_votes.values("candidate_id")
        .annotate(total=Count("id"))
        .order_by("-total")
    )

    candidate_names = {
        c.id: c.name for c in Candidate.objects.filter(topic_id=topic_id)
    }

    candidates = [
        {
            "candidate_id": r["candidate_id"],
            "candidate_name": candidate_names.get(r["candidate_id"]),
            "votes": r["total"],
        }
        for r in counts
    ]

    total_votes = todos_votes.count()
    total_registered = None
    if topic.election:
        total_registered = VoterRegistration.objects.filter(
            election=topic.election, is_active=True
        ).count()

    participation_percent = (
        round((total_votes / total_registered) * 100, 2)
        if total_registered
        else None
    )

    return {
        "topic_id": topic_id,
        "topic_title": topic.title,
        "total_votes": total_votes,
        "total_registered": total_registered,
        "participation_percent": participation_percent,
        "now": timezone.now().isoformat(),
        "candidates": candidates,
    }


def all_results():
    """Hasil seluruh topik (rekap) — untuk endpoint stats & snapshot global."""
    from topics.models import Topic

    topics = Topic.objects.all()
    return [topic_results(t.id) for t in topics]


def topic_evidence(topic_id):
    """Bukti ringkas (lightweight) untuk satu topik:
    total suara + aggregate root hash dari seluruh vote integrity_hash.
    Tidak mengirim detail per-suara → load ringan untuk device, tetap terverifikasi."""
    import hashlib
    from .models import Vote
    from candidates.models import Candidate
    from topics.models import Topic

    topic = Topic.objects.filter(pk=topic_id).first()
    if not topic:
        return {"error": "topic_not_found"}

    votes = list(Vote.objects.filter(topic_id=topic_id).order_by("id"))
    # fold root hash atas integrity_hash tiap suara (deterministik & murah)
    root = ""
    for v in votes:
        root = hashlib.sha256((root + v.integrity_hash).encode()).hexdigest()

    counts = (
        Vote.objects.filter(topic_id=topic_id)
        .values("candidate_id")
        .annotate(total=Count("id"))
    )
    cmap = {c.id: c.name for c in Candidate.objects.filter(topic_id=topic_id)}
    results = [
        {"candidate_id": r["candidate_id"], "candidate_name": cmap.get(r["candidate_id"]), "votes": r["total"]}
        for r in counts
    ]
    return {
        "topic_id": topic_id,
        "topic_title": topic.title,
        "total_votes": len(votes),
        "evidence_root": root,
        "candidates": results,
    }


def all_evidence():
    from topics.models import Topic

    return [topic_evidence(t.id) for t in Topic.objects.all()]


def recap():
    """Rekap resmi (gaya Ci.Cii): hasil per wilayah untuk tiap periode + total.

    Struktur dikembalikan sebagai manifest untuk tanda tangan digital
    (lihat ``votes/signature.py``).
    """
    from django.db.models import Count
    from .models import Vote
    from candidates.models import Candidate
    from topics.models import Topic
    from election.models import ElectionPeriod, Region

    def _named(rows):
        names = {c.id: c.name for c in Candidate.objects.filter(id__in=[r["candidate_id"] for r in rows])}
        return [
            {
                "candidate_id": r["candidate_id"],
                "candidate_name": names.get(r["candidate_id"]),
                "votes": r["total"],
            }
            for r in rows
        ]

    def _registered(election, region=None):
        q = VoterRegistration.objects.filter(election=election, is_active=True)
        if region is not None:
            q = q.filter(region=region)
        return q.count()

    def _participation(votes, registered):
        return round((votes / registered) * 100, 2) if registered else None

    elections = ElectionPeriod.objects.all()
    regions = Region.objects.all()

    out = []
    for election in elections:
        topic_ids = list(election.topic_set.values_list("id", flat=True))
        votes = Vote.objects.filter(topic_id__in=topic_ids) if topic_ids else Vote.objects.none()

        totals = votes.values("candidate_id").annotate(total=Count("id")).order_by("-total")

        region_rows = []
        for region in regions:
            rv = votes.filter(topic__region_id=region.id)
            if not rv.exists():
                continue
            cands = rv.values("candidate_id").annotate(total=Count("id")).order_by("-total")
            region_rows.append({
                "region_id": region.id,
                "region_name": region.name,
                "total_votes": rv.count(),
                "total_registered": _registered(election, region),
                "participation_percent": _participation(rv.count(), _registered(election, region)),
                "candidates": _named(cands),
            })

        registered = _registered(election)
        out.append({
            "election_id": election.id,
            "election_name": election.name,
            "start_at": election.start_at.isoformat(),
            "end_at": election.end_at.isoformat(),
            "regions": region_rows,
            "totals": {
                "total_votes": votes.count(),
                "total_registered": registered,
                "participation_percent": _participation(votes.count(), registered),
                "candidates": _named(totals),
            },
        })

    # topik digabung tanpa periode → bucket "Umum"
    legacy_topic_ids = list(Topic.objects.filter(election__isnull=True).values_list("id", flat=True))
    if legacy_topic_ids:
        lv = Vote.objects.filter(topic_id__in=legacy_topic_ids)
        lt = lv.values("candidate_id").annotate(total=Count("id")).order_by("-total")
        out.append({
            "election_id": None,
            "election_name": "Umum (tanpa periode)",
            "start_at": None,
            "end_at": None,
            "regions": [],
            "totals": {
                "total_votes": lv.count(),
                "total_registered": None,
                "participation_percent": None,
                "candidates": _named(lt),
            },
        })

    return out