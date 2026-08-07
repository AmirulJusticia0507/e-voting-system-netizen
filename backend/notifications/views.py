from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from roles.permissions import HasPermission
from users.models import User
from .models import Notification, Broadcast
from .serializers import NotificationSerializer, BroadcastSerializer
from . import services


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """Notifikasi milik user yang sedang login."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=False, methods=["get"])
    def unread_count(self, request):
        count = self.get_queryset().filter(is_read=False).count()
        return Response({"unread": count})

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=["is_read"])
        return Response({"ok": True})

    @action(detail=False, methods=["post"])
    def mark_all_read(self, request):
        self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({"ok": True})


class BroadcastViewSet(viewsets.ReadOnlyModelViewSet):
    """Broadcast admin ke semua netizen; menyimpan riwayat + push FCM."""
    queryset = Broadcast.objects.all()
    serializer_class = BroadcastSerializer
    permission_classes = [HasPermission]

    def get_permissions(self):
        from roles.permissions import ManageUsersPermission

        if self.request.method in ("POST",):
            return [ManageUsersPermission()]
        return super().get_permissions()

    @action(detail=False, methods=["post"])
    def send(self, request):
        title = str(request.data.get("title", "")).strip()
        body = str(request.data.get("body", "")).strip()
        link = str(request.data.get("link", "")).strip()
        if not title:
            return Response({"detail": "title wajib ada."}, status=400)

        netizens = User.objects.filter(is_active=True, is_netizen=True)
        targets = 0
        fcm_ids = []
        for u in netizens.iterator():
            Notification.objects.create(
                recipient=u, title=title, body=body, link=link
            )
            targets += 1
            if u.fcm_token:
                fcm_ids.append(u.fcm_token)

        b = Broadcast.objects.create(
            title=title, body=body, link=link, targets=targets
        )

        from audit.services import record

        record(
            "notification.broadcast",
            actor=request.user if request.user.is_authenticated else None,
            target_type="broadcast",
            target_pk=b.id,
            request=request,
            detail={"title": title, "targets": targets},
        )

        push_sent = services.send_push(fcm_ids, title, body, link) if fcm_ids else False

        return Response({
            "broadcast_id": b.id,
            "targets": targets,
            "fcm_sent": push_sent,
        }, status=status.HTTP_201_CREATED)