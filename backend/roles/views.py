from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import SAFE_METHODS, IsAuthenticated
from .models import Role, Permission
from .serializers import RoleSerializer, PermissionSerializer
from .permissions import ManageRolesPermission


class PermissionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Permission.objects.all().order_by("code")
    serializer_class = PermissionSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return [IsAuthenticated()]
        return [ManageRolesPermission()]


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all().order_by("name")
    serializer_class = RoleSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return [IsAuthenticated()]
        return [ManageRolesPermission()]

    def get_queryset(self):
        qs = super().get_queryset()
        active = self.request.query_params.get("is_active")
        if active is not None:
            qs = qs.filter(is_active=active in ("1", "true", "True"))
        return qs

    def perform_destroy(self, instance):
        if instance.is_system:
            from rest_framework.exceptions import ValidationError

            raise ValidationError("Role sistem tidak boleh dihapus.")
        from audit.services import record

        record(
            "role.delete",
            actor=self.request.user if self.request.user.is_authenticated else None,
            target_type="role",
            target_pk=instance.id,
            request=self.request,
            detail={"name": instance.name},
        )
        instance.delete()

    def perform_create(self, serializer):
        instance = serializer.save()
        self._audit(instance, "role.create")

    def perform_update(self, serializer):
        instance = serializer.save()
        self._audit(instance, "role.update")

    def _audit(self, instance, action):
        try:
            from audit.services import record

            record(
                action,
                actor=self.request.user if self.request.user.is_authenticated else None,
                target_type="role",
                target_pk=instance.id,
                request=self.request,
                detail={"name": instance.name, "permissions": instance.permission_codes()},
            )
        except Exception:
            pass