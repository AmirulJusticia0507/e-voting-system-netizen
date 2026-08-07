from rest_framework import serializers
from .models import Notification, Broadcast


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "body", "link", "is_read", "created_at"]


class BroadcastSerializer(serializers.ModelSerializer):
    class Meta:
        model = Broadcast
        fields = ["id", "title", "body", "link", "targets", "created_at"]