from django.db import models
from django.utils import timezone


class Region(models.Model):
    name = models.CharField(max_length=100, unique=True)
    code = models.CharField(max_length=20, unique=True)

    def __str__(self):
        return self.name

    class Meta:
        ordering = ["name"]


class ElectionPeriod(models.Model):
    """Satu periode pemilihan (misal: Pilkada 2026, Pemilu 2026, Pilkades).
    Periode bisa berjalan bersamaan; memuat banyak Topik (ballot)."""

    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    start_at = models.DateTimeField()
    end_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    @property
    def ongoing(self):
        now = timezone.now()
        return self.is_active and self.start_at <= now <= self.end_at

    @property
    def has_started(self):
        return timezone.now() >= self.start_at

    class Meta:
        ordering = ["-start_at"]


class VoterRegistration(models.Model):
    """Daftar Pemilih Tetap (DPT): user terdaftar sah untuk memilih pada suatu periode."""

    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="voter_registrations")
    election = models.ForeignKey(
        ElectionPeriod, on_delete=models.CASCADE, related_name="voters"
    )
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    registered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "election")

    def __str__(self):
        return f"{self.user.phone_number} @ {self.election.name}"