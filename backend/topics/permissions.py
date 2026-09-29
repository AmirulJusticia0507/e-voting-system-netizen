import hashlib
import hmac
import time

from django.conf import settings
from rest_framework.permissions import BasePermission


class LexDSSImportPermission(BasePermission):
    message = "Signature Lex-DSS tidak valid."

    def has_permission(self, request, view):
        user = request.user
        if user.is_authenticated and (
            user.is_superuser or user.has_permission("manage_topics")
        ):
            return True

        secret = settings.LEX_DSS_HMAC_SECRET
        timestamp = request.headers.get("X-Lex-Timestamp", "")
        signature = request.headers.get("X-Lex-Signature", "")
        try:
            fresh = abs(time.time() - int(timestamp)) <= 300
        except ValueError:
            return False
        if not secret or not fresh:
            return False

        message = timestamp.encode() + b"." + request.body
        expected = hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()
        return hmac.compare_digest(signature.removeprefix("sha256="), expected)
