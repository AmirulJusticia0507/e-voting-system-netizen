from rest_framework import serializers
from .models import Candidate

class CandidateSerializer(serializers.ModelSerializer):
    likes = serializers.ReadOnlyField(source="total_likes")
    dislikes = serializers.ReadOnlyField(source="total_dislikes")

    class Meta:
        model = Candidate
        fields = ["id", "topic", "name", "photo", "bio", "likes", "dislikes"]

