from django.contrib import admin
from .models import Notification, Broadcast


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("recipient", "title", "is_read", "created_at")
    list_filter = ("is_read", "created_at")
    search_fields = ("title", "recipient__phone_number")


@admin.register(Broadcast)
class BroadcastAdmin(admin.ModelAdmin):
    list_display = ("title", "targets", "created_at")
    search_fields = ("title",)