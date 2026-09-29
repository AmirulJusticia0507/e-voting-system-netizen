from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models


class Topic(models.Model):
    class TopicType(models.TextChoices):
        ELECTION = "election", "Election"
        CIVIC_POLL = "civic_poll", "Civic poll"

    class PublicationStatus(models.TextChoices):
        DRAFT = "draft", "Draft"
        IN_REVIEW = "in_review", "In review"
        PUBLISHED = "published", "Published"
        CLOSED = "closed", "Closed"

    title = models.CharField(max_length=200)
    external_event_id = models.CharField(
        max_length=100, unique=True, null=True, blank=True
    )
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    topic_type = models.CharField(
        max_length=20,
        choices=TopicType.choices,
        default=TopicType.ELECTION,
    )
    publication_status = models.CharField(
        max_length=20,
        choices=PublicationStatus.choices,
        default=PublicationStatus.PUBLISHED,
    )
    disclaimer = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_topics",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    published_at = models.DateTimeField(null=True, blank=True)
    opens_at = models.DateTimeField(null=True, blank=True)
    closes_at = models.DateTimeField(null=True, blank=True)
    is_voided = models.BooleanField(default=False)
    correction_reason = models.TextField(blank=True)
    superseded_by = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="superseded_topics",
    )
    election = models.ForeignKey(
        "election.ElectionPeriod",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="topic_set",
        help_text="Periode pemilihan yang menaungi topik ini.",
    )
    region = models.ForeignKey(
        "election.Region",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="topic_set",
        help_text="Wilayah yang hanya punya topik ini (kosong = nasional).",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class CivicPollSource(models.Model):
    class SourceType(models.TextChoices):
        VIDEO = "video", "Video"
        DOCUMENT = "document", "Document"
        TRANSCRIPT = "transcript", "Transcript"
        OTHER = "other", "Other"

    topic = models.OneToOneField(
        Topic,
        on_delete=models.CASCADE,
        related_name="civic_source",
    )
    source_type = models.CharField(max_length=20, choices=SourceType.choices)
    url = models.URLField(blank=True)
    publisher = models.CharField(max_length=200, blank=True)
    title = models.CharField(max_length=255)
    segment_start_seconds = models.PositiveIntegerField(null=True, blank=True)
    segment_end_seconds = models.PositiveIntegerField(null=True, blank=True)
    content_hash = models.CharField(max_length=128, blank=True)
    transcript_excerpt = models.TextField(blank=True)
    legal_audit = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def clean(self):
        if self.topic_id and self.topic.topic_type != Topic.TopicType.CIVIC_POLL:
            raise ValidationError(
                {"topic": "Source hanya dapat dipasang pada civic poll."}
            )
        if (
            self.segment_start_seconds is not None
            and self.segment_end_seconds is not None
            and self.segment_end_seconds < self.segment_start_seconds
        ):
            raise ValidationError(
                {"segment_end_seconds": "Akhir segmen tidak boleh sebelum awal segmen."}
            )

    def __str__(self):
        return f"{self.title} ({self.topic.title})"
