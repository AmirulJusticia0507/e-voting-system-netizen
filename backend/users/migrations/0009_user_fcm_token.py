from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0008_user_gamification"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="fcm_token",
            field=models.CharField(blank=True, default="", max_length=255),
        ),
    ]