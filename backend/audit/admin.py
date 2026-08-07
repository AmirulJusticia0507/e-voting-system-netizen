from django.contrib import admin
from .models import AuditLog


class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("timestamp", "action", "actor", "target_type", "target_pk", "ip_address")
    list_filter = ("action",)
    search_fields = ("action", "target_pk", "ip_address")


admin.site.register(AuditLog, AuditLogAdmin)