from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0007_user_otp_expires"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="points",
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name="user",
            name="vote_streak",
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name="user",
            name="last_vote_date",
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="user",
            name="badges",
            field=models.JSONField(blank=True, default=list),
        ),
    ]