from rest_framework import viewsets
from rest_framework.permissions import SAFE_METHODS
from .models import Topic
from .serializers import TopicSerializer
from roles.permissions import ManageTopicsPermission


class TopicViewSet(viewsets.ModelViewSet):
    queryset = Topic.objects.all()
    serializer_class = TopicSerializer

    def get_permissions(self):
        # baca untuk siapa saja, tulis (create/update/delete) butuh manage_topics
        if self.request.method in SAFE_METHODS:
            return []
        return [ManageTopicsPermission()]

    def get_queryset(self):
        return Topic.objects.all().order_by("-created_at")