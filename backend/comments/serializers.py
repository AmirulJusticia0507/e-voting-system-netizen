from rest_framework import serializers
from .models import Comment

class CommentSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()

    
    def get_username(self, obj):
        if obj.user:
            return obj.user.username or obj.user.phone_number
        return "Anonymous"

    class Meta:
        model = Comment
        fields = ["id", "user", "username", "topic", "candidate", "text", "likes", "dislikes", "is_reported", "created_at"]
        extra_kwargs = {
            "user": {"required": False, "allow_null": True}
        }

