from django.contrib import admin
from .models import Topic

@admin.register(Topic)
class TopicAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "is_active", "created_at")
    search_fields = ("title",)
    list_filter = ("is_active", "created_at")
