from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import AuditLog
from .serializers import AuditLogSerializer
from .services import compute_hash


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.select_related("actor").order_by("-id")
    serializer_class = AuditLogSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["get"])
    def chain(self, request):
        logs = AuditLog.objects.order_by("id")
        items = []
        prev = "AUDIT_GENESIS"
        valid_chain = True
        for log in logs:
            expected = compute_hash(
                prev,
                log.action,
                log.actor_id,
                log.target_type,
                log.target_pk,
                log.detail,
                log.nonce,
            )
            link_ok = (log.previous_hash == prev) and (expected == log.integrity_hash)
            if not link_ok:
                valid_chain = False
            items.append({
                "id": log.id,
                "timestamp": log.timestamp.isoformat(),
                "action": log.action,
                "actor": log.actor_id,
                "previous_hash": log.previous_hash,
                "integrity_hash": log.integrity_hash,
                "link_valid": link_ok,
            })
            prev = log.integrity_hash
        return Response({"total": len(items), "chain_valid": valid_chain, "logs": items})