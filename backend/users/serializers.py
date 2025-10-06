from rest_framework import serializers
from .models import User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"

class PhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'phone_number'
