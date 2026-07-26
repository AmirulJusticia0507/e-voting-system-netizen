from rest_framework import serializers
from .models import Vote

class VoteSerializer(serializers.ModelSerializer):
    candidate_name = serializers.ReadOnlyField(source="candidate.name")
    topic_title = serializers.ReadOnlyField(source="topic.title")

    class Meta:
        model = Vote
        fields = ["id", "user", "topic", "candidate", "candidate_name", "topic_title", "created_at"]
        extra_kwargs = {
            "user": {"required": False, "allow_null": True}
        }

