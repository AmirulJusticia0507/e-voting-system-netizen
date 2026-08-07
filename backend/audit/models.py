from django.db import models


class AuditLog(models.Model):
    """Log keamanan/aktivitas berantai (anti-tamper), gaya append-only.

    Tiap catatan menimpan ``integrity_hash`` = HMAC(prev_hash, action, ...).
    Mengubahan satu catatan akan merusak rantai setelahnya.
    """

    timestamp = models.DateTimeField(auto_now_add=True)
    actor = models.ForeignKey(
        "users.User", null=True, blank=True, on_delete=models.SET_NULL, related_name="audit_logs"
    )
    action = models.CharField(max_length=100)
    target_type = models.CharField(max_length=60, blank=True, default="")
    target_pk = models.CharField(max_length=60, blank=True, default="")
    ip_address = models.CharField(max_length=100, blank=True, default="")
    user_agent = models.TextField(blank=True, default="")
    detail = models.JSONField(default=dict, blank=True)

    previous_hash = models.CharField(max_length=128, blank=True, default="")
    integrity_hash = models.CharField(max_length=128, blank=True, default="")
    nonce = models.CharField(max_length=64, blank=True, default="")

    def __str__(self):
        return f"{self.timestamp:%Y-%m-%d %H:%M} {self.action}"

    class Meta:
        ordering = ["-timestamp"]