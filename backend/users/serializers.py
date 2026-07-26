from rest_framework import serializers
from .models import User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "phone_number",
            "username",
            "photo",
            "is_verified",
            "is_staff",
            "is_superuser",
            "is_netizen",
            "created_at",
        ]
        read_only_fields = ["id", "is_verified", "is_staff", "is_superuser", "created_at"]

class PhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'phone_number'

