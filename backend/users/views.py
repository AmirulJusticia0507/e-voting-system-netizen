from rest_framework import viewsets, status
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.views import APIView
from django.contrib.auth import authenticate, get_user_model
from .serializers import PhoneTokenObtainPairSerializer, UserSerializer

User = get_user_model()


# 🔹 CRUD User via ViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @action(detail=False, methods=["get", "patch"], permission_classes=[IsAuthenticated])
    def me(self, request):
        user = request.user
        if request.method == "PATCH":
            serializer = self.get_serializer(user, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        serializer = self.get_serializer(user)
        return Response(serializer.data)



@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    identifier = request.data.get("identifier")  # bisa phone_number atau username
    password = request.data.get("password")

    # 🔹 cek pakai phone_number
    user = authenticate(request, phone_number=identifier, password=password)

    # 🔹 kalau gagal, coba pakai username
    if user is None:
        try:
            user_obj = User.objects.get(username=identifier)
            user = authenticate(request, phone_number=user_obj.phone_number, password=password)
        except User.DoesNotExist:
            user = None

    if user is not None:
        refresh = RefreshToken.for_user(user)
        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": {
                "id": user.id,
                "phone_number": user.phone_number,
                "username": getattr(user, "username", None),
                "is_staff": user.is_staff,
            }
        })
    else:
        return Response({"detail": "Invalid credentials"}, status=401)


# ✅ JWT login dengan phone_number
class PhoneTokenObtainPairView(TokenObtainPairView):
    serializer_class = PhoneTokenObtainPairSerializer


# ✅ login khusus admin
class AdminLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(request, username=username, password=password)

        if user and user.is_staff:
            refresh = RefreshToken.for_user(user)
            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": {
                    "id": user.id,
                    "username": getattr(user, "username", None),
                    "phone_number": user.phone_number,
                    "is_staff": user.is_staff,
                }
            })
        return Response({"detail": "Invalid admin credentials"}, status=status.HTTP_401_UNAUTHORIZED)
