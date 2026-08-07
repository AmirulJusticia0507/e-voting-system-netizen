# netizens/serializers.py
from rest_framework import serializers
from users.models import User
from django.contrib.auth.hashers import make_password

class NetizenSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['phone_number', 'password', 'photo']  # tambahkan field lain kalau perlu
        extra_kwargs = {
            "password": {"write_only": True}
        }

    def create(self, validated_data):
        # hash password
        validated_data['password'] = make_password(validated_data['password'])
        # paksa user jadi netizen
        validated_data['is_netizen'] = True
        # role default → netizen
        try:
            from roles.models import Role
            default_role = Role.objects.filter(name="netizen", is_active=True).first()
            validated_data['roles'] = default_role
        except Exception:
            pass
        # username fallback → pakai phone_number kalau kosong
        if not validated_data.get("username"):
            validated_data["username"] = validated_data["phone_number"]
        return User.objects.create(**validated_data)
