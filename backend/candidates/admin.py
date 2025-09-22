from django.contrib import admin
from .models import Candidate

@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "topic")
    search_fields = ("name",)
    list_filter = ("topic",)
