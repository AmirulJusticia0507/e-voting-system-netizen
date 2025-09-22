# backend/users/views.py
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import UserSerializer

# 🔹 CRUD User biasa
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer


# 🔹 Admin login via username/password (Django admin)
class AdminLoginView(APIView):
    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        if not username or not password:
            return Response(
                {"detail": "Username dan password wajib diisi."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # authenticate user dari User model bawaan Django admin
        user = authenticate(username=username, password=password)

        if user and user.is_staff:
            refresh = RefreshToken.for_user(user)
            return Response({"token": str(refresh.access_token)}, status=status.HTTP_200_OK)
        else:
            return Response(
                {"detail": "Username atau password salah / bukan admin."},
                status=status.HTTP_401_UNAUTHORIZED
            )
