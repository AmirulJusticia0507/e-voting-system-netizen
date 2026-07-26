from rest_framework import viewsets
from .models import Comment
from .serializers import CommentSerializer
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

from users.models import User

class CommentViewSet(viewsets.ModelViewSet):
    serializer_class = CommentSerializer

    def get_queryset(self):
        queryset = Comment.objects.all().order_by("-created_at")
        topic_id = self.request.query_params.get("topic")
        if topic_id:
            queryset = queryset.filter(topic_id=topic_id)
        return queryset

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
