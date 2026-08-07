import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("roles", "0001_initial"),
        ("users", "0005_user_is_netizen"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="roles",
            field=models.ForeignKey(
                blank=True,
                help_text="Primary role pengguna.",
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="users",
                to="roles.role",
            ),
        ),
    ]