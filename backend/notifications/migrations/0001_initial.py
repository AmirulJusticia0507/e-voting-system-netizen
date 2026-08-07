import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ("users", "0008_user_gamification"),
    ]

    operations = [
        migrations.CreateModel(
            name="Broadcast",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                ("title", models.CharField(max_length=200)),
                ("body", models.TextField(blank=True)),
                ("link", models.CharField(blank=True, default="", max_length=300)),
                ("targets", models.IntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={"ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="Notification",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False, verbose_name="ID"
                    ),
                ),
                ("title", models.CharField(max_length=200)),
                ("body", models.TextField(blank=True)),
                ("link", models.CharField(blank=True, default="", max_length=300)),
                ("is_read", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "recipient",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="notifications",
                        to="users.user",
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]