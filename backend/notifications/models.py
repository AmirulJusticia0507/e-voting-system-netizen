from django.db import models
from users.models import User


class Notification(models.Model):
    """Notifikasi in-app yang diterima seorang user (pertukaran dengan FCM push)."""

    recipient = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="notifications"
    )
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True)
    link = models.CharField(max_length=300, blank=True, default="")
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.recipient.phone_number}: {self.title}"


class Broadcast(models.Model):
    """Riwayat broadcast admin (ke semua netizen) — untuk audit & re-broadcast."""

    title = models.CharField(max_length=200)
    body = models.TextField(blank=True)
    link = models.CharField(max_length=300, blank=True, default="")
    targets = models.IntegerField(default=0, help_text="Jumlah user yang menerima.")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title