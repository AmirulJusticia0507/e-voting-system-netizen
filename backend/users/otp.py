"""Layanan OTP untuk verifikasi pemilih.

Alur:
1. `issue_otp(user)`  → generate 6 digit, simpan di user, kirim lewat WhatsApp.
2. `verify_otp(user, code)` → cek benar & belum kedaluwarsa, tandai `is_verified`.
"""
import random
import logging
from datetime import timedelta

import requests
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)

OTP_LENGTH = 6
OTP_TTL_MINUTES = 10


def _clean_phone(phone_number: str) -> str:
    clean = str(phone_number).strip().replace("+", "").replace("-", "").replace(" ", "")
    if clean.startswith("0"):
        clean = "62" + clean[1:]
    return clean


def generate_otp() -> str:
    return f"{random.randint(0, 10**OTP_LENGTH - 1):0{OTP_LENGTH}d}"


def send_otp_whatsapp(user, otp: str) -> bool:
    """Kirim kode OTP via WhatsApp Gateway (fallback log simulasi jika tanpa token)."""
    phone = getattr(user, "phone_number", None)
    if not phone:
        return False
    clean_phone = _clean_phone(phone)

    message = (
        f"🔐 *E-VOTING SYSTEM NETIZEN*\n\n"
        f"Halo *{getattr(user, 'username', None) or phone}*,\n"
        f"Kode verifikasi Anda adalah:\n\n"
        f"*{otp}*\n\n"
        f"Berlaku selama {OTP_TTL_MINUTES} menit. Jangan bagikan ke siapa pun.\n"
        f"Gunakan kode ini untuk memverifikasi akun sebelum voting."
    )

    url = getattr(settings, "WA_GATEWAY_URL", "https://api.fonnte.com/send")
    token = getattr(settings, "WA_GATEWAY_TOKEN", None)

    try:
        if token:
            resp = requests.post(
                url,
                headers={"Authorization": token},
                data={"target": clean_phone, "message": message},
                timeout=5,
            )
            logger.info(f"WA OTP response ({resp.status_code}): {resp.text}")
            return resp.status_code == 200
        logger.info(f"[WA SIMULATION] OTP untuk {clean_phone}: {otp}")
        print(f"\n[OTP SIMULATION] Target: {clean_phone}\n{message}\n")
        return True
    except Exception as e:
        logger.error(f"Gagal kirim OTP WhatsApp: {e}")
        return False


def issue_otp(user) -> str:
    otp = generate_otp()
    user.otp_code = otp
    user.otp_expires_at = timezone.now() + timedelta(minutes=OTP_TTL_MINUTES)
    user.save(update_fields=["otp_code", "otp_expires_at"])
    send_otp_whatsapp(user, otp)
    return otp


def verify_otp(user, code: str):
    """Return ``(ok, reason)``. ok=True menandakan sukses & user ditandai terverifikasi."""
    if not user.otp_code or not user.otp_expires_at:
        return False, "no_otp"
    if timezone.now() > user.otp_expires_at:
        return False, "expired"
    if user.otp_code != str(code).strip():
        return False, "invalid"

    user.is_verified = True
    user.otp_code = None
    user.otp_expires_at = None
    user.save(update_fields=["is_verified", "otp_code", "otp_expires_at"])
    return True, "ok"