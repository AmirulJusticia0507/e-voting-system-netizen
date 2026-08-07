from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import SAFE_METHODS
from .models import Comment
from .serializers import CommentSerializer
from users.models import User
from roles.permissions import (
    ManageCommentsPermission,
    CanComment,
)


class CommentViewSet(viewsets.ModelViewSet):
    serializer_class = CommentSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return []
        return [ManageCommentsPermission() if False else CanComment()]

    def get_queryset(self):
        queryset = Comment.objects.all().order_by("-created_at")
        topic_id = self.request.query_params.get("topic")
        if topic_id:
            queryset = queryset.filter(topic_id=topic_id)
        return queryset

    def get_object(self):
        obj = super().get_object()
        return obj

    def perform_destroy(self, instance):
        user = self.request.user
        # pemilik komentar / punya manage_comments / superuser boleh hapus
        if user.is_superuser or user.has_permission("manage_comments") or instance.user_id == user.id:
            instance.delete()
            return
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("Anda tidak diizinkan menghapus komentar ini.")

    def perform_create(self, serializer):
        if "user" not in serializer.validated_data or serializer.validated_data["user"] is None:
            user = self.request.user if self.request.user.is_authenticated else User.objects.first()
            serializer.save(user=user)
        else:
            serializer.save()


    @action(detail=True, methods=["post"])
    def like(self, request, pk=None):
        comment = self.get_object()
        comment.likes += 1
        comment.save()
        return Response({"likes": comment.likes})

    @action(detail=True, methods=["post"])
    def dislike(self, request, pk=None):
        comment = self.get_object()
        comment.dislikes += 1
        comment.save()
        return Response({"dislikes": comment.dislikes})