from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import SAFE_METHODS
from rest_framework.response import Response

from roles.permissions import ManageTopicsPermission

from .models import Topic
from .serializers import CivicPollImportSerializer, TopicSerializer


class TopicViewSet(viewsets.ModelViewSet):
    queryset = Topic.objects.all()
    serializer_class = TopicSerializer

    def get_permissions(self):
        # baca untuk siapa saja, tulis (create/update/delete) butuh manage_topics
        if self.request.method in SAFE_METHODS:
            return []
        return [ManageTopicsPermission()]

    def get_queryset(self):
        return (
            Topic.objects.select_related("election", "region", "civic_source")
            .prefetch_related("candidates")
            .order_by("-created_at")
        )

    @action(detail=False, methods=["post"], url_path="import-civic-draft")
    def import_civic_draft(self, request):
        serializer = CivicPollImportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        topic = serializer.save()
        return Response(
            TopicSerializer(topic, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )
