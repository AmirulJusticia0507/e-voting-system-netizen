from django.urls import path
from .views import (
    admin_dashboard,
    users_dashboard, create_user, update_user, delete_user,
    topics_dashboard, create_topic, update_topic, delete_topic,
    candidates_dashboard, create_candidate, update_candidate, delete_candidate,
    votes_dashboard, delete_vote,
    comments_dashboard, delete_comment,
)

urlpatterns = [
    path("", admin_dashboard, name="admin_dashboard"),

    # Users
    path("users/", users_dashboard, name="users_dashboard"),
    path("users/create/", create_user, name="create_user"),
    path("users/update/<int:pk>/", update_user, name="update_user"),
    path("users/delete/<int:pk>/", delete_user, name="delete_user"),

    # Topics
    path("topics/", topics_dashboard, name="topics_dashboard"),
    path("topics/create/", create_topic, name="create_topic"),
    path("topics/update/<int:pk>/", update_topic, name="update_topic"),
    path("topics/delete/<int:pk>/", delete_topic, name="delete_topic"),

    # Candidates
    path("candidates/", candidates_dashboard, name="candidates_dashboard"),
    path("candidates/create/", create_candidate, name="create_candidate"),
    path("candidates/update/<int:pk>/", update_candidate, name="update_candidate"),
    path("candidates/delete/<int:pk>/", delete_candidate, name="delete_candidate"),

    # Votes
    path("votes/", votes_dashboard, name="votes_dashboard"),
    path("votes/delete/<int:pk>/", delete_vote, name="delete_vote"),

    # Comments
    path("comments/", comments_dashboard, name="comments_dashboard"),
    path("comments/delete/<int:pk>/", delete_comment, name="delete_comment"),
]
