from rest_framework import serializers
from .models import User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from roles.models import Role


class UserSerializer(serializers.ModelSerializer):
    role = serializers.PrimaryKeyRelatedField(
        queryset=Role.objects.all(), source="roles", required=False, allow_null=True
    )
    role_name = serializers.SerializerMethodField()
    permission_codes = serializers.SerializerMethodField()

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
            "role",
            "role_name",
            "permission_codes",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "is_verified",
            "is_staff",
            "is_superuser",
            "role_name",
            "permission_codes",
            "created_at",
        ]

    def get_role_name(self, obj):
        return obj.role_name

    def get_permission_codes(self, obj):
        return obj.permission_codes()


class PhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'phone_number'