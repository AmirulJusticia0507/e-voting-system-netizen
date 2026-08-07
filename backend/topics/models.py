from django.db import models

class Topic(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    election = models.ForeignKey(
        "election.ElectionPeriod",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="topic_set",
        help_text="Periode pemilihan yang menaungi topik ini.",
    )
    region = models.ForeignKey(
        "election.Region",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="topic_set",
        help_text="Wilayah yang relevant untuk topik ini (kosong = nasional).",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
