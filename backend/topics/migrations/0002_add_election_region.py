import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("election", "0001_initial"),
        ("topics", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="topic",
            name="election",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="topic_set",
                to="election.electionperiod",
                help_text="Periode pemilihan yang menaungi topik ini.",
            ),
        ),
        migrations.AddField(
            model_name="topic",
            name="region",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="topic_set",
                to="election.region",
                help_text="Wilayah yang hanya punya topik ini (kosong = nasional).",
            ),
        ),
    ]