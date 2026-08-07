"""Pengiriman push via FCM (dipakai saat broadcast). Aman di-skip bila belum dikonfigurasi."""
import json
import logging

from django.conf import settings

logger = logging.getLogger(__name__)


def fcm_configured() -> bool:
    return bool(getattr(settings, "FCM_SERVER_KEY", ""))


def send_push(registration_ids, title, body, link=""):
    """Kirim push memakai FCM HTTP v1 (legacy) ber-`requests`.
    Tidak melakukan apa-apa bila FCM_SERVER_KEY kosong (fallback ke in-app)."""
    if not fcm_configured() or not registration_ids:
        return False
    try:
        import requests

        payload = {
            "registration_ids": list(dict.fromkeys(registration_ids)),
            "notification": {"title": title, "body": body},
            "data": {"link": link},
        }
        resp = requests.post(
            "https://fcm.googleapis.com/fcm/send",
            headers={
                "Authorization": f"key={settings.FCM_SERVER_KEY}",
                "Content-Type": "application/json",
            },
            data=json.dumps(payload),
            timeout=10,
        )
        resp.raise_for_status()
        return True
    except Exception as e:
        logger.warning("FCM push gagal: %s", e)
        return False