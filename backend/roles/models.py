from django.db import models


class Permission(models.Model):
    """Predefined permission / capability in the system."""
    code = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)

    def __str__(self):
        return f"{self.name} ({self.code})"

    class Meta:
        ordering = ["code"]


class Role(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    permissions = models.ManyToManyField(
        Permission, related_name="roles", blank=True
    )
    is_system = models.BooleanField(
        default=False, help_text="System roles (superadmin/netizen) tidak bisa dihapus."
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    def permission_codes(self):
        return list(self.permissions.values_list("code", flat=True))