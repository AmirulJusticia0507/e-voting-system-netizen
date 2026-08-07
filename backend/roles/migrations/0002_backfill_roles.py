from django.db import migrations


def backfill(apps, schema_editor):
    User = apps.get_model("users", "User")
    Role = apps.get_model("roles", "Role")

    try:
        superadmin = Role.objects.get(name="superadmin")
        admin = Role.objects.get(name="admin")
        netizen = Role.objects.get(name="netizen")
    except Role.DoesNotExist:
        return

    for u in User.objects.all():
        if u.is_superuser:
            u.roles = superadmin
        elif u.is_staff:
            u.roles = admin
        else:
            u.roles = netizen
        u.save(update_fields=["roles"])


class Migration(migrations.Migration):

    dependencies = [
        ("roles", "0001_initial"),
        ("users", "0006_user_roles"),
    ]

    operations = [
        migrations.RunPython(backfill, migrations.RunPython.noop),
    ]