from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from roles.models import Permission

class UserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError("Phone number must be set")
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)

        if not extra_fields.get("username"):
            raise ValueError("Superuser must have a username")

        return self.create_user(phone_number, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    phone_number = models.CharField(max_length=20, unique=True)
    username = models.CharField(max_length=150, unique=True, blank=True, null=True)  # 🔹 tambahan
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    otp_expires_at = models.DateTimeField(null=True, blank=True)
    photo = models.ImageField(upload_to="users/photos/", blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    is_netizen = models.BooleanField(default=False)

    # ---- V7-B3: Gamification ----
    points = models.IntegerField(default=0)
    vote_streak = models.IntegerField(default=0)
    last_vote_date = models.DateField(null=True, blank=True)
    badges = models.JSONField(default=list, blank=True)

    roles = models.ForeignKey(
        "roles.Role",
        related_name="users",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Primary role pengguna.",
    )
    objects = UserManager()

    USERNAME_FIELD = "phone_number"       # tetap pakai nomor HP untuk netizen
    REQUIRED_FIELDS = ["username"]        # superuser wajib isi username

    def __str__(self):
        return self.username or self.phone_number

    @property
    def role_name(self):
        if self.roles:
            return self.roles.name
        if self.is_superuser:
            return "superadmin"
        return ""

    def has_permission(self, code):
        """Return True jika pengguna memiliki permission `code`."""
        if self.is_superuser:
            return True
        if self.roles and self.roles.is_active:
            return self.roles.permissions.filter(code=code).exists()
        return False

    def permission_codes(self):
        """Daftar code permission yang dimiliki pengguna."""
        if self.is_superuser:
            return list(Permission.objects.values_list("code", flat=True))
        if self.roles and self.roles.is_active:
            return list(self.roles.permissions.values_list("code", flat=True))
        return []
