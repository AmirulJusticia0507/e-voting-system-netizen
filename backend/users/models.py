from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

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
    photo = models.ImageField(upload_to="users/photos/", blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    is_netizen = models.BooleanField(default=False)
    objects = UserManager()

    USERNAME_FIELD = "phone_number"       # tetap pakai nomor HP untuk netizen
    REQUIRED_FIELDS = ["username"]        # superuser wajib isi username

    def __str__(self):
        return self.username or self.phone_number
