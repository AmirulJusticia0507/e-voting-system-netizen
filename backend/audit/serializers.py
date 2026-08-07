from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import AuditLog

User = get_user_model()


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = AuditLog
        fields = [
            "id",
            "timestamp",
            "actor",
            "actor_name",
            "action",
            "target_type",
            "target_pk",
            "ip_address",
            "user_agent",
            "detail",
            "previous_hash",
            "integrity_hash",
        ]

    def get_actor_name(self, obj):
        if obj.actor:
            return obj.actor.username or obj.actor.phone_number
        return None