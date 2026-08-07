from rest_framework import viewsets, status
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.views import APIView
from django.contrib.auth import authenticate, get_user_model
from django.conf import settings
from .serializers import PhoneTokenObtainPairSerializer, UserSerializer
from roles.models import Role
from roles.permissions import ManageUsersPermission
from .otp import issue_otp, verify_otp, OTP_TTL_MINUTES

User = get_user_model()


def _user_payload(user):
    return {
        "id": user.id,
        "phone_number": user.phone_number,
        "username": getattr(user, "username", None),
        "is_staff": user.is_staff,
        "is_superuser": user.is_superuser,
        "is_verified": user.is_verified,
        "role_name": user.role_name,
        "permission_codes": user.permission_codes(),
    }


# 🔹 CRUD User via ViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [ManageUsersPermission]

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

    @action(detail=True, methods=["post"], permission_classes=[ManageUsersPermission])
    def set_role(self, request, pk=None):
        from audit.services import record

        user = self.get_object()
        role_id = request.data.get("role")
        if role_id is None:
            return Response(
                {"detail": "Field `role` wajib diisi."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            role = Role.objects.get(pk=role_id, is_active=True)
        except Role.DoesNotExist:
            return Response(
                {"detail": "Role tidak ditemukan / tidak aktif."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Role admin/superadmin harus tetap punya is_staff agar bisa akses dashboard
        if role.name in ("admin", "superadmin"):
            user.is_staff = True
        elif not user.is_superuser:
            user.is_staff = False

        user.roles = role
        user.save()
        from audit.services import record

        record(
            "user.set_role",
            actor=request.user if request.user.is_authenticated else None,
            target_type="user",
            target_pk=user.id,
            request=request,
            detail={"user": user.phone_number, "role": role.name},
        )
        return Response(self.get_serializer(user).data)

    @action(detail=False, methods=["get"], permission_classes=[ManageUsersPermission])
    def roles(self, request):
        roles = Role.objects.filter(is_active=True).values("id", "name", "description")
        return Response(list(roles))



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
        from audit.services import record

        record(
            "auth.login", actor=user, target_type="user", target_pk=user.id, request=request
        )
        refresh = RefreshToken.for_user(user)
        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": _user_payload(user),
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
            from audit.services import record

            record(
                "auth.admin_login", actor=user, target_type="user", target_pk=user.id, request=request
            )
            refresh = RefreshToken.for_user(user)
            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": _user_payload(user),
            })
        return Response({"detail": "Invalid admin credentials"}, status=status.HTTP_401_UNAUTHORIZED)


# ✅ Request kode OTP (verifikasi pemilih)
class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = str(request.data.get("phone_number", "")).strip()
        if not phone:
            return Response({"detail": "phone_number wajib diisi."}, status=400)

        user = User.objects.filter(phone_number=phone).first()
        if not user:
            return Response({"detail": "Nomor tidak terdaftar."}, status=404)

        otp = issue_otp(user)

        from audit.services import record

        record(
            "auth.otp.request",
            actor=user,
            target_type="user",
            target_pk=user.id,
            request=request,
            detail={"phone": user.phone_number},
        )

        # di mode debug, kembalikan kode supaya mudah dites
        payload = {
            "detail": "Kode OTP terkirim.",
            "expires_in_minutes": OTP_TTL_MINUTES,
            "is_verified": user.is_verified,
        }
        if settings.DEBUG:
            payload["dev_otp"] = otp
        return Response(payload, status=200)


# ✅ Verifikasi OTP → tandai terverifikasi + beri token
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = str(request.data.get("phone_number", "")).strip()
        code = str(request.data.get("otp", "")).strip()
        if not phone or not code:
            return Response({"detail": "phone_number dan otp wajib diisi."}, status=400)

        user = User.objects.filter(phone_number=phone).first()
        if not user:
            return Response({"detail": "User tidak terdaftar."}, status=404)

        ok, reason = verify_otp(user, code)
        if not ok:
            from audit.services import record

            record(
                "auth.otp.verify.fail",
                actor=user,
                target_type="user",
                target_pk=user.id,
                request=request,
                detail={"reason": reason},
            )
            return Response({"detail": "OTP tidak valid."}, status=400)

        from audit.services import record

        record(
            "auth.otp.verify",
            actor=user,
            target_type="user",
            target_pk=user.id,
            request=request,
        )
        refresh = RefreshToken.for_user(user)
        return Response({
            "detail": "Verifikasi berhasil.",
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": _user_payload(user),
        }, status=200)