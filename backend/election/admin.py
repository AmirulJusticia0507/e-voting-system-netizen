from django.contrib import admin
from .models import Region, ElectionPeriod, VoterRegistration


class VoterRegistrationInline(admin.TabularInline):
    model = VoterRegistration
    extra = 0
    autocomplete_fields = ["user"]


class ElectionPeriodAdmin(admin.ModelAdmin):
    list_display = ("name", "start_at", "end_at", "is_active")
    list_filter = ("is_active",)
    inlines = [VoterRegistrationInline]


admin.site.register(Region)
admin.site.register(ElectionPeriod, ElectionPeriodAdmin)
admin.site.register(VoterRegistration)