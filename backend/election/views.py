from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import SAFE_METHODS, IsAuthenticated
from django.contrib.auth import get_user_model

from .models import Region, ElectionPeriod, VoterRegistration
from .serializers import RegionSerializer, ElectionPeriodSerializer, VoterRegistrationSerializer
from roles.permissions import ManageElectionsPermission


User = get_user_model()


class RegionViewSet(viewsets.ModelViewSet):
    queryset = Region.objects.all().order_by("name")
    serializer_class = RegionSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return [IsAuthenticated()]
        return [ManageElectionsPermission()]

    def perform_create(self, serializer):
        inst = serializer.save()
        self._audit("region.create", inst)

    def perform_update(self, serializer):
        inst = serializer.save()
        self._audit("region.update", inst)

    def perform_destroy(self, instance):
        self._audit("region.delete", instance)
        instance.delete()

    def _audit(self, action, instance):
        try:
            from audit.services import record

            record(
                action,
                actor=self.request.user if self.request.user.is_authenticated else None,
                target_type="region",
                target_pk=instance.id,
                request=self.request,
                detail={"name": instance.name},
            )
        except Exception:
            pass


class ElectionPeriodViewSet(viewsets.ModelViewSet):
    queryset = ElectionPeriod.objects.all().order_by("-start_at")
    serializer_class = ElectionPeriodSerializer

    def get_permissions(self):
        if self.request.method in SAFE_METHODS:
            return [IsAuthenticated()]
        return [ManageElectionsPermission()]

    def _audit(self, action, target_pk, instance):
        try:
            from audit.services import record

            record(
                action,
                actor=self.request.user if self.request.user.is_authenticated else None,
                target_type="election",
                target_pk=target_pk,
                request=self.request,
                detail={"name": getattr(instance, "name", None)},
            )
        except Exception:
            pass

    def perform_create(self, serializer):
        instance = serializer.save()
        self._audit("election.create", instance.id, instance)

    def perform_update(self, serializer):
        instance = serializer.save()
        self._audit("election.update", instance.id, instance)

    def perform_destroy(self, instance):
        self._audit("election.delete", instance.id, instance)
        instance.delete()

    # ✅ DPT: daftarkan/matikan seorang pemilih utk periode ini
    @action(detail=True, methods=["get", "post"], permission_classes=[ManageElectionsPermission])
    def voters(self, request, pk=None):
        election = self.get_object()

        if request.method == "GET":
            qs = election.voters.select_related("user", "region")
            active = request.query_params.get("is_active")
            if active is not None:
                qs = qs.filter(is_active=active in ("1", "true", "True"))
            serializer = VoterRegistrationSerializer(qs, many=True)
            return Response(serializer.data)

        # POST {phone_number, region?}
        phone = str(request.data.get("phone_number", "")).strip()
        if not phone:
            raise ValidationError({"phone_number": "wajib diisi"})
        user = User.objects.filter(phone_number=phone).first()
        if not user:
            raise ValidationError({"phone_number": "Nomor tidak terdaftar."})

        region_id = request.data.get("region")
        region = Region.objects.filter(pk=region_id).first() if region_id else None

        registration, created = VoterRegistration.objects.update_or_create(
            user=user,
            election=election,
            defaults={
                "region": region,
                "is_active": str(request.data.get("is_active", "true")).lower() in ("1", "true"),
            },
        )
        self._audit("dpt.register" if created else "dpt.update", election.id, election)
        return Response(
            VoterRegistrationSerializer(registration).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    @action(detail=True, methods=["post"], permission_classes=[ManageElectionsPermission])
    def remove_voter(self, request, pk=None):
        election = self.get_object()
        voter_id = request.data.get("voter_id")
        election.voters.filter(pk=voter_id).delete()
        return Response({"detail": "Pemilih dihapus dari DPT."}, status=200)