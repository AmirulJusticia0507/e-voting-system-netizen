from rest_framework import serializers
from users.models import User
from django.contrib.auth.hashers import make_password

class NetizenSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['phone_number', 'password']

    def create(self, validated_data):
        # Hash password
        validated_data['password'] = make_password(validated_data['password'])
        user = User.objects.create(**validated_data, is_netizen=True)
        return user
