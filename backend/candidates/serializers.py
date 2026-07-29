from rest_framework import serializers
from .models import Candidate

class CandidateSerializer(serializers.ModelSerializer):
    likes = serializers.ReadOnlyField(source="total_likes")
    dislikes = serializers.ReadOnlyField(source="total_dislikes")
    vote_count = serializers.SerializerMethodField()
    vote_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Candidate
        fields = ["id", "topic", "name", "photo", "bio", "likes", "dislikes", "vote_count", "vote_percentage"]
        extra_kwargs = {
            "photo": {"required": False, "allow_null": True}
        }

    def get_vote_count(self, obj):
        return obj.votes.count()

    def get_vote_percentage(self, obj):
        total_topic_votes = obj.topic.votes.count()
        if total_topic_votes > 0:
            return round((obj.votes.count() / total_topic_votes) * 100, 1)
        return 0.0


