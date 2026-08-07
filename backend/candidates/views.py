from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import SAFE_METHODS
from rest_framework.response import Response
from .models import Candidate
from .serializers import CandidateSerializer
from comments.models import Comment
from users.models import User
from roles.permissions import ManageCandidatesPermission, IsNetizenVoter


class CandidateViewSet(viewsets.ModelViewSet):
    serializer_class = CandidateSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return []
        return [ManageCandidatesPermission()]

    def get_queryset(self):
        queryset = Candidate.objects.all()
        topic_id = self.request.query_params.get("topic")
        if topic_id:
            queryset = queryset.filter(topic_id=topic_id)
        return queryset

    @action(detail=True, methods=["post"], permission_classes=[IsNetizenVoter])
    def like(self, request, pk=None):
        candidate = self.get_object()
        user = request.user if request.user.is_authenticated else User.objects.first()
        comment = candidate.comments.first()
        if not comment:
            if user:
                comment = Comment.objects.create(
                    user=user,
                    topic=candidate.topic,
                    candidate=candidate,
                    text="Liked candidate",
                    likes=1
                )
        else:
            comment.likes += 1
            comment.save()
        return Response({"status": "liked", "likes": candidate.total_likes})

    @action(detail=True, methods=["post"], permission_classes=[IsNetizenVoter])
    def dislike(self, request, pk=None):
        candidate = self.get_object()
        user = request.user if request.user.is_authenticated else User.objects.first()
        comment = candidate.comments.first()
        if not comment:
            if user:
                comment = Comment.objects.create(
                    user=user,
                    topic=candidate.topic,
                    candidate=candidate,
                    text="Disliked candidate",
                    dislikes=1
                )
        else:
            comment.dislikes += 1
            comment.save()
        return Response({"status": "disliked", "dislikes": candidate.total_dislikes})