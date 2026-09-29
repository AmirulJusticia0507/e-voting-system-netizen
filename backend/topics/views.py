from django.db.models import Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import SAFE_METHODS
from rest_framework.response import Response

from audit.services import record
from roles.permissions import ManageTopicsPermission

from .models import Topic
from .permissions import LexDSSImportPermission
from .serializers import (
    CivicPollCorrectionSerializer,
    CivicPollImportSerializer,
    TopicSerializer,
)


class TopicViewSet(viewsets.ModelViewSet):
    queryset = Topic.objects.all()
    serializer_class = TopicSerializer

    def get_permissions(self):
        # baca untuk siapa saja, tulis (create/update/delete) butuh manage_topics
        if self.action == "import_civic_draft":
            return [LexDSSImportPermission()]
        if self.request.method in SAFE_METHODS:
            return []
        return [ManageTopicsPermission()]

    def get_queryset(self):
        queryset = (
            Topic.objects.select_related("election", "region", "civic_source")
            .prefetch_related("candidates")
            .order_by("-created_at")
        )
        user = self.request.user
        can_manage = user.is_authenticated and (
            user.is_superuser or user.has_permission("manage_topics")
        )
        if not can_manage:
            queryset = queryset.filter(
                Q(topic_type=Topic.TopicType.ELECTION)
                | Q(publication_status=Topic.PublicationStatus.PUBLISHED)
            )
        return queryset

    @action(detail=False, methods=["post"], url_path="import-civic-draft")
    def import_civic_draft(self, request):
        serializer = CivicPollImportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        existing = Topic.objects.filter(
            external_event_id=serializer.validated_data["event_id"]
        ).first()
        if existing is not None:
            return Response(
                TopicSerializer(existing, context={"request": request}).data,
                status=status.HTTP_200_OK,
            )
        topic = serializer.save()
        record(
            "civic_poll.imported",
            actor=request.user if request.user.is_authenticated else None,
            target_type="topic",
            target_pk=topic.id,
            request=request,
            detail={"event_id": topic.external_event_id},
        )
        return Response(
            TopicSerializer(topic, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="submit-review")
    def submit_review(self, request, pk=None):
        topic = self.get_object()
        error = self._validate_civic_status(topic, Topic.PublicationStatus.DRAFT)
        if error is not None:
            return error
        topic.publication_status = Topic.PublicationStatus.IN_REVIEW
        topic.save(update_fields=["publication_status"])
        record(
            "civic_poll.review_submitted",
            actor=request.user,
            target_type="topic",
            target_pk=topic.id,
            request=request,
        )
        return Response(TopicSerializer(topic, context={"request": request}).data)

    @action(detail=True, methods=["post"])
    def publish(self, request, pk=None):
        topic = self.get_object()
        error = self._validate_civic_status(topic, Topic.PublicationStatus.IN_REVIEW)
        if error is not None:
            return error
        now = timezone.now()
        topic.publication_status = Topic.PublicationStatus.PUBLISHED
        topic.reviewed_by = request.user
        topic.reviewed_at = now
        topic.published_at = now
        topic.is_active = True
        topic.save(
            update_fields=[
                "publication_status",
                "reviewed_by",
                "reviewed_at",
                "published_at",
                "is_active",
            ]
        )
        record(
            "civic_poll.published",
            actor=request.user,
            target_type="topic",
            target_pk=topic.id,
            request=request,
        )
        return Response(TopicSerializer(topic, context={"request": request}).data)

    @action(detail=True, methods=["post"])
    def close(self, request, pk=None):
        topic = self.get_object()
        error = self._validate_civic_status(topic, Topic.PublicationStatus.PUBLISHED)
        if error is not None:
            return error
        topic.publication_status = Topic.PublicationStatus.CLOSED
        topic.is_active = False
        topic.save(update_fields=["publication_status", "is_active"])
        record(
            "civic_poll.closed",
            actor=request.user,
            target_type="topic",
            target_pk=topic.id,
            request=request,
        )
        return Response(TopicSerializer(topic, context={"request": request}).data)

    @action(detail=True, methods=["post"])
    def correct(self, request, pk=None):
        topic = self.get_object()
        if topic.topic_type != Topic.TopicType.CIVIC_POLL:
            return Response(
                {"detail": "Aksi ini hanya berlaku untuk civic poll."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = CivicPollCorrectionSerializer(data=request.data, context={})
        serializer.is_valid(raise_exception=True)
        successor = serializer.context["successor"]
        if successor.id == topic.id:
            return Response(
                {"detail": "Polling tidak dapat menggantikan dirinya sendiri."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        topic.is_voided = True
        topic.correction_reason = serializer.validated_data["reason"]
        topic.superseded_by = successor
        topic.publication_status = Topic.PublicationStatus.CLOSED
        topic.is_active = False
        topic.save(
            update_fields=[
                "is_voided",
                "correction_reason",
                "superseded_by",
                "publication_status",
                "is_active",
            ]
        )
        record(
            "civic_poll.corrected",
            actor=request.user,
            target_type="topic",
            target_pk=topic.id,
            request=request,
            detail={
                "reason": topic.correction_reason,
                "superseded_by_event_id": successor.external_event_id,
            },
        )
        return Response(TopicSerializer(topic, context={"request": request}).data)

    @staticmethod
    def _validate_civic_status(topic, expected_status):
        if topic.topic_type != Topic.TopicType.CIVIC_POLL:
            return Response(
                {"detail": "Aksi ini hanya berlaku untuk civic poll."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if topic.publication_status != expected_status:
            return Response(
                {"detail": f"Status harus {expected_status}."},
                status=status.HTTP_409_CONFLICT,
            )
        return None
