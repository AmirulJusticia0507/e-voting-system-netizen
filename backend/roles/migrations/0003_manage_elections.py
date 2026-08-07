from django.db import migrations


def add_manage_elections(apps, schema_editor):
    Permission = apps.get_model("roles", "Permission")
    Role = apps.get_model("roles", "Role")

    perm, _ = Permission.objects.get_or_create(
        code="manage_elections",
        defaults={
            "name": "Kelola Pemilihan & DPT",
            "description": "Mengelola periode pemilihan, wilayah, dan daftar pemilih tetap (DPT).",
        },
    )

    superadmin = Role.objects.filter(name="superadmin").first()
    if superadmin:
        superadmin.permissions.add(perm)

    admin = Role.objects.filter(name="admin").first()
    if admin:
        admin.permissions.add(perm)


def unseed(apps, schema_editor):
    Permission = apps.get_model("roles", "Permission")
    Permission.objects.filter(code="manage_elections").delete()


class Migration(migrations.Migration):

    dependencies = [
        ("roles", "0002_backfill_roles"),
    ]

    operations = [
        migrations.RunPython(add_manage_elections, unseed),
    ]