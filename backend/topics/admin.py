from django.contrib import admin

from .models import CivicPollSource, Topic


@admin.register(Topic)
class TopicAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "title",
        "topic_type",
        "publication_status",
        "is_active",
        "created_at",
    )
    search_fields = ("title",)
    list_filter = ("topic_type", "publication_status", "is_active", "created_at")


@admin.register(CivicPollSource)
class CivicPollSourceAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "publisher", "source_type", "updated_at")
    search_fields = ("title", "publisher", "url")
    list_filter = ("source_type", "updated_at")
