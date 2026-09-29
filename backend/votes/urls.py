from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    VoteViewSet,
    public_results,
    public_share,
    public_hub,
    public_archive,
    public_recap,
    public_recap_verify,
    civic_aggregate,
)

router = DefaultRouter()
router.register(r"", VoteViewSet, basename="vote")

urlpatterns = [
    path("", include(router.urls)),
    path("public/<int:topic_id>/", public_results, name="vote_public_results"),
    path("public/civic/<int:topic_id>/", civic_aggregate, name="civic_aggregate"),
    path("public/share/<int:topic_id>/", public_share, name="vote_public_share"),
    path("public/hub/", public_hub, name="vote_public_hub"),
    path(
        "public/archive/<int:election_id>/", public_archive, name="vote_public_archive"
    ),
    path("public/recap/", public_recap, name="vote_public_recap"),
    path("public/recap/verify/", public_recap_verify, name="vote_public_recap_verify"),
]
