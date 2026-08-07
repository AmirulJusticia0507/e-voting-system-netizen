from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import VoteViewSet, public_results, public_share

router = DefaultRouter()
router.register(r"", VoteViewSet, basename="vote")

urlpatterns = [
    path("", include(router.urls)),
    path("public/<int:topic_id>/", public_results, name="vote_public_results"),
    path("public/share/<int:topic_id>/", public_share, name="vote_public_share"),
]

