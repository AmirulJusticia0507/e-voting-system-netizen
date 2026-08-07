import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="AuditLog",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                ("timestamp", models.DateTimeField(auto_now_add=True)),
                (
                    "actor",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="audit_logs",
                        to="users.user",
                    ),
                ),
                ("action", models.CharField(max_length=100)),
                ("target_type", models.CharField(blank=True, default="", max_length=60)),
                ("target_pk", models.CharField(blank=True, default="", max_length=60)),
                ("ip_address", models.CharField(blank=True, default="", max_length=100)),
                ("user_agent", models.TextField(blank=True, default="")),
                ("detail", models.JSONField(blank=True, default=dict)),
                ("previous_hash", models.CharField(blank=True, default="", max_length=128)),
                ("integrity_hash", models.CharField(blank=True, default="", max_length=128)),
                ("nonce", models.CharField(blank=True, default="", max_length=64)),
            ],
            options={"ordering": ["-timestamp"]},
        ),
    ]