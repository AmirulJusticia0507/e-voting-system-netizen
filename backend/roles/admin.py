from django.contrib import admin
from .models import Role, Permission


class RoleAdmin(admin.ModelAdmin):
    list_display = ("name", "is_system", "is_active", "created_at")
    filter_horizontal = ("permissions",)
    list_filter = ("is_active", "is_system")


admin.site.register(Role, RoleAdmin)
admin.site.register(Permission)