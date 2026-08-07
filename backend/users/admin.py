from django.contrib import admin
from .models import User


class UserAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "username", "role_name", "is_staff", "is_superuser", "is_active")
    list_filter = ("is_staff", "is_superuser", "is_active", "is_netizen", "roles")
    search_fields = ("phone_number", "username")
    raw_id_fields = ("roles",)


admin.site.register(User, UserAdmin)