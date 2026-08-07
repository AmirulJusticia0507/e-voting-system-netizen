"""Pencatatan audit trail berantai (tamper-evident).

Setiap entri disimpan dengan ``integrity_hash`` = HMAC(prev, action, actor,
target, detail, nonce). Bila satu entri diubah, rantai setelahnya rusak dan
mudah terdeteksi lewat endpoint ``chain``.
"""
import hashlib
import hmac
import json
import secrets

from django.conf import settings


def _key() -> bytes:
    return hashlib.sha256(str(settings.VOTE_ENCRYPTION_KEY).encode()).digest()


def client_ip(request) -> str:
    if not request:
        return ""
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "")


def compute_hash(previous_hash, action, actor_id, target_type, target_pk, detail, nonce):
    canonic = json.dumps(detail or {}, sort_keys=True, separators=(",", ":"))
    message = (
        f"{previous_hash}|{action}|{actor_id or ''}|{target_type}"
        f"|{target_pk}|{canonic}|{nonce}"
    )
    return hmac.new(_key(), message.encode(), hashlib.sha256).hexdigest()


def record(action, actor=None, target_type="", target_pk=None, request=None, detail=None):
    from .models import AuditLog

    last = AuditLog.objects.order_by("-id").first()
    prev = last.integrity_hash if last else "AUDIT_GENESIS"
    nonce = secrets.token_hex(8)
    detail = detail or {}
    integrity = compute_hash(
        previous_hash=prev,
        action=action,
        actor_id=getattr(actor, "id", None),
        target_type=target_type,
        target_pk=str(target_pk) if target_pk is not None else "",
        detail=detail,
    )

    return AuditLog.objects.create(
        actor=actor,
        action=action,
        target_type=target_type,
        target_pk=str(target_pk) if target_pk is not None else "",
        ip_address=client_ip(request) if request else "",
        user_agent=request.META.get(
            "HTTP_USER_AGENT", ""
        ) if request else "",
        detail=detail,
        previous_hash=prev,
        integrity_hash=integrity,
        nonce=nonce,
    )