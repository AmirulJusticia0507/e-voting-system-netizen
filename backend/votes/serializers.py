from rest_framework import serializers
from .models import Vote


class VoteSerializer(serializers.ModelSerializer):
    candidate_name = serializers.ReadOnlyField(source="candidate.name")
    topic_title = serializers.ReadOnlyField(source="topic.title")

    class Meta:
        model = Vote
        fields = [
            "id",
            "user",
            "topic",
            "candidate",
            "candidate_name",
            "topic_title",
            "previous_hash",
            "integrity_hash",
            "encrypted_choice",
            "created_at",
        ]
        extra_kwargs = {
            "user": {"required": False, "allow_null": True},
            "previous_hash": {"read_only": True},
            "integrity_hash": {"read_only": True},
            "encrypted_choice": {"read_only": True},
        }