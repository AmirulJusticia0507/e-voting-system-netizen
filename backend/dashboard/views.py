from django.shortcuts import render
from users.models import User
from topics.models import Topic
from candidates.models import Candidate
from votes.models import Vote
from comments.models import Comment

def admin_dashboard(request):
    context = {
        "user_count": User.objects.count(),
        "topic_count": Topic.objects.count(),
        "candidate_count": Candidate.objects.count(),
        "vote_count": Vote.objects.count(),
        "comment_count": Comment.objects.count(),
        "comments": Comment.objects.select_related("user", "topic").order_by("-created_at")[:10],
    }
    return render(request, "dashboard/index.html", context)
