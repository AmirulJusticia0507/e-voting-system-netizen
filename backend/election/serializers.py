from rest_framework import serializers
from django.utils import timezone
from .models import Region, ElectionPeriod, VoterRegistration


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ["id", "name", "code"]


class ElectionPeriodSerializer(serializers.ModelSerializer):
    status = serializers.SerializerMethodField()
    topic_count = serializers.SerializerMethodField()
    voter_count = serializers.SerializerMethodField()

    class Meta:
        model = ElectionPeriod
        fields = [
            "id",
            "name",
            "description",
            "start_at",
            "end_at",
            "is_active",
            "status",
            "topic_count",
            "voter_count",
            "created_at",
        ]
        read_only_fields = ["id", "status", "topic_count", "voter_count", "created_at"]

    def get_status(self, obj):
        if not obj.is_active:
            return "disabled"
        now = timezone.now()
        if obj.start_at <= now <= obj.end_at:
            return "ongoing"
        if now < obj.start_at:
            return "upcoming"
        return "closed"

    def get_topic_count(self, obj):
        return obj.topic_set.count()

    def get_voter_count(self, obj):
        return obj.voters.filter(is_active=True).count()


class VoterRegistrationSerializer(serializers.ModelSerializer):
    region = RegionSerializer(read_only=True)
    phone_number = serializers.CharField(write_only=True, required=False)
    username = serializers.SerializerMethodField()

    class Meta:
        model = VoterRegistration
        fields = [
            "id",
            "election",
            "phone_number",
            "username",
            "region",
            "is_active",
            "registered_at",
        ]
        read_only_fields = ["id", "election", "username", "registered_at"]
        extra_kwargs = {"region": {"required": False}}

    def get_username(self, obj):
        return obj.user.username or obj.user.phone_number

    def create(self, validated_data):
        from django.contrib.auth import get_user_model
        from rest_framework.exceptions import ValidationError

        phone = str(validated_data.pop("phone_number", "")).strip()
        user = get_user_model().objects.filter(phone_number=phone).first()
        if not user:
            raise ValidationError({"phone_number": "Nomor tidak terdaftar."})
        validated_data["user"] = user
        return super().create(validated_data)