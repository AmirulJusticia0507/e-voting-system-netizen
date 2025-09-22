from django.contrib import admin
from .models import Vote

@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "topic", "candidate", "created_at")
    search_fields = ("user__phone_number", "candidate__name")
    list_filter = ("topic", "created_at")
