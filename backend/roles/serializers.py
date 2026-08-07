from rest_framework import serializers
from .models import Role, Permission


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ["id", "code", "name", "description"]


class RoleSerializer(serializers.ModelSerializer):
    permissions = serializers.PrimaryKeyRelatedField(
        queryset=Permission.objects.all(), many=True, required=False
    )
    permission_codes = serializers.SerializerMethodField()
    user_count = serializers.SerializerMethodField()

    class Meta:
        model = Role
        fields = [
            "id",
            "name",
            "description",
            "permissions",
            "permission_codes",
            "is_system",
            "is_active",
            "user_count",
            "created_at",
        ]
        read_only_fields = ["id", "is_system", "user_count", "created_at"]

    def get_permission_codes(self, obj):
        return obj.permission_codes()

    def get_user_count(self, obj):
        return obj.users.count()