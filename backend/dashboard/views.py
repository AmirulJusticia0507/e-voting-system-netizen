from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from users.models import User
from topics.models import Topic
from candidates.models import Candidate
from votes.models import Vote
from comments.models import Comment

# Dashboard utama
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

# ----------------- USERS -----------------
def users_dashboard(request):
    users = User.objects.all()
    return render(request, "dashboard/users.html", {"users": users})

def create_user(request):
    if request.method == "POST":
        phone_number = request.POST.get("phone_number")
        if phone_number:
            User.objects.create(phone_number=phone_number)
            messages.success(request, "User berhasil dibuat.")
        return redirect("users_dashboard")
    return render(request, "dashboard/users_form.html", {"action": "create"})

def update_user(request, pk):
    user = get_object_or_404(User, pk=pk)
    if request.method == "POST":
        user.phone_number = request.POST.get("phone_number")
        user.save()
        messages.success(request, "User berhasil diupdate.")
        return redirect("users_dashboard")
    return render(request, "dashboard/users_form.html", {"action": "update", "user": user})

def delete_user(request, pk):
    user = get_object_or_404(User, pk=pk)
    user.delete()
    messages.success(request, "User berhasil dihapus.")
    return redirect("users_dashboard")

# ----------------- TOPICS -----------------
def topics_dashboard(request):
    topics = Topic.objects.all()
    return render(request, "dashboard/topics.html", {"topics": topics})

def create_topic(request):
    if request.method == "POST":
        title = request.POST.get("title")
        description = request.POST.get("description")
        if title:
            Topic.objects.create(title=title, description=description)
            messages.success(request, "Topic berhasil dibuat.")
        return redirect("topics_dashboard")
    return render(request, "dashboard/topics_form.html", {"action": "create"})

def update_topic(request, pk):
    topic = get_object_or_404(Topic, pk=pk)
    if request.method == "POST":
        topic.title = request.POST.get("title")
        topic.description = request.POST.get("description")
        topic.save()
        messages.success(request, "Topic berhasil diupdate.")
        return redirect("topics_dashboard")
    return render(request, "dashboard/topics_form.html", {"action": "update", "topic": topic})

def delete_topic(request, pk):
    topic = get_object_or_404(Topic, pk=pk)
    topic.delete()
    messages.success(request, "Topic berhasil dihapus.")
    return redirect("topics_dashboard")

# ----------------- CANDIDATES -----------------
def candidates_dashboard(request):
    candidates = Candidate.objects.select_related("topic").all()
    return render(request, "dashboard/candidates.html", {"candidates": candidates})

def create_candidate(request):
    topics = Topic.objects.all()
    if request.method == "POST":
        name = request.POST.get("name")
        topic_id = request.POST.get("topic")
        topic = get_object_or_404(Topic, pk=topic_id)
        Candidate.objects.create(name=name, topic=topic)
        messages.success(request, "Candidate berhasil dibuat.")
        return redirect("candidates_dashboard")
    return render(request, "dashboard/candidates_form.html", {"action": "create", "topics": topics})

def update_candidate(request, pk):
    candidate = get_object_or_404(Candidate, pk=pk)
    topics = Topic.objects.all()
    if request.method == "POST":
        candidate.name = request.POST.get("name")
        topic_id = request.POST.get("topic")
        candidate.topic = get_object_or_404(Topic, pk=topic_id)
        candidate.save()
        messages.success(request, "Candidate berhasil diupdate.")
        return redirect("candidates_dashboard")
    return render(request, "dashboard/candidates_form.html", {"action": "update", "candidate": candidate, "topics": topics})

def delete_candidate(request, pk):
    candidate = get_object_or_404(Candidate, pk=pk)
    candidate.delete()
    messages.success(request, "Candidate berhasil dihapus.")
    return redirect("candidates_dashboard")

# ----------------- VOTES -----------------
def votes_dashboard(request):
    votes = Vote.objects.select_related("user", "candidate", "topic").all()
    return render(request, "dashboard/votes.html", {"votes": votes})

def delete_vote(request, pk):
    vote = get_object_or_404(Vote, pk=pk)
    vote.delete()
    messages.success(request, "Vote berhasil dihapus.")
    return redirect("votes_dashboard")

# ----------------- COMMENTS -----------------
def comments_dashboard(request):
    comments = Comment.objects.select_related("user", "topic").all()
    return render(request, "dashboard/comments.html", {"comments": comments})

def delete_comment(request, pk):
    comment = get_object_or_404(Comment, pk=pk)
    comment.delete()
    messages.success(request, "Comment berhasil dihapus.")
    return redirect("comments_dashboard")
