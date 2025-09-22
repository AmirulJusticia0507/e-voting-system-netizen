from django.db import models

class User(models.Model):
    phone_number = models.CharField(max_length=20, unique=True)
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    photo = models.ImageField(upload_to="users/photos/", blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.phone_number
