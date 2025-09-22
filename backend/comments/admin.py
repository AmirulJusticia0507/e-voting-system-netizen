from django.contrib import admin
from .models import Comment

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "topic", "text", "likes", "dislikes", "is_reported", "created_at")
    search_fields = ("user__phone_number", "text")
    list_filter = ("is_reported", "created_at", "topic")
