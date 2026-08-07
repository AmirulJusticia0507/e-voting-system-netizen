import django.db.models.deletion
from django.db import migrations, models


ALL_PERMISSIONS = [
    ("manage_users", "Kelola User", "Melihat & mengelola akun pengguna"),
    ("manage_topics", "Kelola Topik", "Membuat, mengubah dan menghapus topik"),
    ("manage_candidates", "Kelola Kandidat", "Membuat, mengubah dan menghapus kandidat"),
    ("manage_votes", "Kelola Votes", "Melihat data seluruh suara"),
    ("manage_comments", "Kelola Komentar", "Menghapus komentar yang melanggar"),
    ("manage_roles", "Kelola Role & Permission", "Mengelola role, permission dan penugasan"),
    ("vote", "Voting", "Memilih pada topik yang aktif"),
    ("comment", "Berkomentar", "Memberi komentar / like / dislike"),
    ("view_results", "Lihat Hasil", "Melihat hasil vote"),
]


def seed(apps, schema_editor):
    Permission = apps.get_model("roles", "Permission")
    Role = apps.get_model("roles", "Role")

    perms = {}
    for code, name, desc in ALL_PERMISSIONS:
        p, _ = Permission.objects.get_or_create(
            code=code, defaults={"name": name, "description": desc}
        )
        perms[code] = p

    superadmin, _ = Role.objects.get_or_create(
        name="superadmin",
        defaults={
            "description": "Akses penuh ke semua fungsi sistem.",
            "is_system": True,
        },
    )
    superadmin.permissions.set(Permission.objects.all())

    admin, _ = Role.objects.get_or_create(
        name="admin",
        defaults={
            "description": "Mengelola konten voting dan memoderasi komentar.",
            "is_system": False,
        },
    )
    admin.permissions.set([
        perms["manage_users"],
        perms["manage_topics"],
        perms["manage_candidates"],
        perms["manage_votes"],
        perms["manage_comments"],
        perms["view_results"],
        perms["comment"],
    ])

    netizen, _ = Role.objects.get_or_create(
        name="netizen",
        defaults={
            "description": "Warga biasa: voting dan berkomentar.",
            "is_system": True,
        },
    )
    netizen.permissions.set([
        perms["vote"],
        perms["comment"],
        perms["view_results"],
    ])


def unseed(apps, schema_editor):
    Role = apps.get_model("roles", "Role")
    Role.objects.filter(name__in=["superadmin", "admin", "netizen"]).delete()


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Permission",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("code", models.CharField(max_length=100, unique=True)),
                ("name", models.CharField(max_length=150)),
                ("description", models.TextField(blank=True)),
            ],
            options={"ordering": ["code"]},
        ),
        migrations.CreateModel(
            name="Role",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True, primary_key=True, serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("name", models.CharField(max_length=100, unique=True)),
                ("description", models.TextField(blank=True)),
                (
                    "permissions",
                    models.ManyToManyField(
                        blank=True, related_name="roles", to="roles.permission"
                    ),
                ),
                (
                    "is_system",
                    models.BooleanField(
                        default=False,
                        help_text="Role sistem tidak bisa dihapus.",
                    ),
                ),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.RunPython(seed, unseed),
    ]