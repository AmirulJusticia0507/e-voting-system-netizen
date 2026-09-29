from django.db import transaction
from rest_framework import serializers

from candidates.models import Candidate
from election.models import Region

from .models import CivicPollSource, Topic


class CivicPollSourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CivicPollSource
        exclude = ("topic",)
        read_only_fields = ("id", "created_at", "updated_at")


class CivicPollSourceInputSerializer(serializers.Serializer):
    type = serializers.ChoiceField(
        choices=["youtube_video", "video", "document", "transcript", "other"]
    )
    url = serializers.URLField(required=False, allow_blank=True)
    publisher = serializers.CharField(max_length=200, required=False, allow_blank=True)
    title = serializers.CharField(max_length=255)
    segment_start_seconds = serializers.IntegerField(
        min_value=0, required=False, allow_null=True
    )
    segment_end_seconds = serializers.IntegerField(
        min_value=0, required=False, allow_null=True
    )
    content_hash = serializers.CharField(
        max_length=128, required=False, allow_blank=True
    )
    transcript_excerpt = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        start = attrs.get("segment_start_seconds")
        end = attrs.get("segment_end_seconds")
        if start is not None and end is not None and end < start:
            raise serializers.ValidationError(
                "segment_end_seconds tidak boleh sebelum segment_start_seconds."
            )
        return attrs


class PollOptionSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=20)
    label = serializers.CharField(max_length=200)


class PollDraftSerializer(serializers.Serializer):
    question = serializers.CharField(max_length=200)
    description = serializers.CharField(required=False, allow_blank=True)
    disclaimer = serializers.CharField(required=False, allow_blank=True)
    options = PollOptionSerializer(many=True, min_length=2)
    opens_at = serializers.DateTimeField(required=False, allow_null=True)
    closes_at = serializers.DateTimeField(required=False, allow_null=True)
    region_code = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        opens_at = attrs.get("opens_at")
        closes_at = attrs.get("closes_at")
        if opens_at and closes_at and closes_at <= opens_at:
            raise serializers.ValidationError("closes_at harus setelah opens_at.")
        return attrs


class CivicPollImportSerializer(serializers.Serializer):
    schema_version = serializers.CharField(max_length=20)
    event_id = serializers.CharField(max_length=100)
    generated_at = serializers.DateTimeField()
    source = CivicPollSourceInputSerializer()
    legal_audit = serializers.JSONField(required=False, default=dict)
    poll_draft = PollDraftSerializer()
    review = serializers.JSONField(required=False, default=dict)

    def validate_schema_version(self, value):
        if value != "1.0":
            raise serializers.ValidationError("Versi schema yang didukung hanya 1.0.")
        return value

    @transaction.atomic
    def create(self, validated_data):
        source_data = validated_data["source"]
        source_type = source_data.pop("type")
        if source_type in {"youtube_video", "video"}:
            source_type = CivicPollSource.SourceType.VIDEO

        poll_data = validated_data["poll_draft"]
        region_code = poll_data.pop("region_code", "")
        options = poll_data.pop("options")
        legal_audit = validated_data.get("legal_audit", {})
        description = poll_data.pop("description", "") or legal_audit.get("summary", "")
        region = None
        if region_code:
            try:
                region = Region.objects.get(code=region_code)
            except Region.DoesNotExist as exc:
                raise serializers.ValidationError(
                    {"poll_draft": {"region_code": "Kode wilayah tidak ditemukan."}}
                ) from exc

        topic = Topic.objects.create(
            external_event_id=validated_data["event_id"],
            title=poll_data.pop("question"),
            description=description,
            disclaimer=poll_data.pop(
                "disclaimer",
                "Jajak pendapat konsultatif; hasilnya bukan keputusan hukum yang mengikat.",
            ),
            topic_type=Topic.TopicType.CIVIC_POLL,
            publication_status=Topic.PublicationStatus.DRAFT,
            is_active=False,
            region=region,
            **poll_data,
        )
        CivicPollSource.objects.create(
            topic=topic,
            source_type=source_type,
            legal_audit=legal_audit,
            **source_data,
        )
        Candidate.objects.bulk_create(
            [
                Candidate(topic=topic, code=option["code"], name=option["label"])
                for option in options
            ]
        )
        return topic


class CivicPollCorrectionSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=2000)
    superseded_by_event_id = serializers.CharField(max_length=100)

    def validate_superseded_by_event_id(self, value):
        try:
            successor = Topic.objects.get(
                external_event_id=value,
                topic_type=Topic.TopicType.CIVIC_POLL,
            )
        except Topic.DoesNotExist as exc:
            raise serializers.ValidationError(
                "Polling pengganti belum tersedia."
            ) from exc
        self.context["successor"] = successor
        return value


class TopicSerializer(serializers.ModelSerializer):
    election_name = serializers.SerializerMethodField()
    region_name = serializers.SerializerMethodField()
    civic_source = CivicPollSourceSerializer(read_only=True)
    options = serializers.SerializerMethodField()

    class Meta:
        model = Topic
        fields = "__all__"
        read_only_fields = ("election_name", "region_name")

    def get_election_name(self, obj):
        return obj.election.name if obj.election else None

    def get_region_name(self, obj):
        return obj.region.name if obj.region else None

    def get_options(self, obj):
        return [
            {"id": option.id, "code": option.code, "label": option.name}
            for option in obj.candidates.all()
        ]
