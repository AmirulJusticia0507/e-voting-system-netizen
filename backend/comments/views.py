from rest_framework import viewsets
from .models import Comment
from .serializers import CommentSerializer
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer

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
