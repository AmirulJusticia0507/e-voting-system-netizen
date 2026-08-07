"""V7-B3: Gamification — poin, streak, badge, dan papan peringkat pemilih."""
from django.utils import timezone

BADGE_STREAKS = {
    3: "streak_3",
    7: "streak_7",
    30: "streak_30",
}

POINTS_PER_VOTE = 10


def award_vote(user):
    """Berikan poin & update streak saat user berhasil memilih.
    Dipanggil dari votes.views.perform_create setelah vote tersimpan."""
    today = timezone.localdate()

    if user.last_vote_date == today:
        # sudah vote hari ini → cukup tambah poin, tanpa naik streak ganda
        user.points += POINTS_PER_VOTE
        user.save(update_fields=["points"])
        return None

    if user.last_vote_date == today - timezone.timedelta(days=1):
        user.vote_streak += 1  # lanjut streak
    else:
        user.vote_streak = 1  # reset streak (atau mulai baru)

    user.last_vote_date = today
    user.points += POINTS_PER_VOTE

    # badge berbasis streak
    new_badges = []
    badge_code = BADGE_STREAKS.get(user.vote_streak)
    if badge_code and badge_code not in user.badges:
        user.badges.append(badge_code)
        new_badges.append(badge_code)

    # badge vote pertama
    if user.points == POINTS_PER_VOTE and "first_vote" not in user.badges:
        user.badges.append("first_vote")
        new_badges.append("first_vote")

    user.save(
        update_fields=["points", "vote_streak", "last_vote_date", "badges"]
    )
    return new_badges


def user_gamification(user):
    """Ringkasan gamifikasi untuk satu user."""
    from users.models import User

    rank = (
        User.objects.filter(points__gt=user.points, is_netizen=True).count() + 1
    )
    return {
        "points": user.points,
        "vote_streak": user.vote_streak,
        "last_vote_date": user.last_vote_date.isoformat() if user.last_vote_date else None,
        "badges": user.badges or [],
        "rank": rank,
    }


def leaderboard():
    """Top netizen berdasarkan poin."""
    from users.models import User

    rows = User.objects.filter(is_netizen=True).order_by("-points", "id")[:10]
    return [
        {
            "id": u.id,
            "username": u.username or u.phone_number,
            "points": u.points,
            "vote_streak": u.vote_streak,
            "badges": u.badges or [],
        }
        for u in rows
    ]


DISPLAY_BADGES = {
    "first_vote": {"label": "Voter Pertama", "icon": "🎯"},
    "streak_3": {"label": "3 Hari Beruntun", "icon": "🔥"},
    "streak_7": {"label": "Seminggu Kuat", "icon": "⚡"},
    "streak_30": {"label": "Sebulan Loyal", "icon": "👑"},
}