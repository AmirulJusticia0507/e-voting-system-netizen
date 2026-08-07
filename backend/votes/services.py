import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

def send_whatsapp_vote_notification(vote):
    """
    Mengirimkan notifikasi bukti voting via WhatsApp Gateway API.
    """
    user = vote.user
    phone_number = getattr(user, 'phone_number', None)
    if not phone_number:
        logger.warning(f"Tidak dapat mengirim WhatsApp: User {user} tidak memiliki nomor telepon.")
        return False

    # Format nomor telepon ke standar internasional 62...
    clean_phone = str(phone_number).strip().replace("+", "").replace("-", "").replace(" ", "")
    if clean_phone.startswith("0"):
        clean_phone = "62" + clean_phone[1:]

    topic_title = vote.topic.title if hasattr(vote, 'topic') and vote.topic else "Topik Voting"
    candidate_name = vote.candidate.name if hasattr(vote, 'candidate') and vote.candidate else "Kandidat Pilihan"
    vote_time = vote.created_at.strftime("%d-%m-%Y %H:%M:%S") if hasattr(vote, 'created_at') and vote.created_at else "-"

    message = (
        f"🗳️ *E-VOTING SYSTEM NETIZEN*\n\n"
        f"Halo *{user.username}*,\n"
        f"Terima kasih! Suara Anda telah berhasil dicatat pada sistem e-voting kami.\n\n"
        f"📋 *Rincian Bukti Voting:*\n"
        f"• *Topik:* {topic_title}\n"
        f"• *Pilihan:* {candidate_name}\n"
        f"• *Nomor Pemilih:* {clean_phone}\n"
        f"• *Waktu Vote:* {vote_time}\n\n"
        f"Terima kasih atas partisipasi Anda dalam menjaga transparansi & demokrasi netizen! 🚀"
    )

    # 🔹 Gateway Configuration (Dukungan Fonnte / Wablas / Generic HTTP Gateway)
    wa_gateway_url = getattr(settings, 'WA_GATEWAY_URL', 'https://api.fonnte.com/send')
    wa_token = getattr(settings, 'WA_GATEWAY_TOKEN', None)

    try:
        if wa_token:
            response = requests.post(
                wa_gateway_url,
                headers={"Authorization": wa_token},
                data={
                    "target": clean_phone,
                    "message": message,
                },
                timeout=5
            )
            logger.info(f"WhatsApp API Response ({response.status_code}): {response.text}")
            return response.status_code == 200
        else:
            # Fallback Simulation / Logging jika belum memasang API Key Vendor WA
            logger.info(f"[WHATSAPP SIMULATION] Kirim ke {clean_phone}:\n{message}")
            print(f"\n================ [WHATSAPP NOTIFICATION SENT] ================\nTarget: {clean_phone}\n{message}\n===============================================================\n")
            return True
    except Exception as e:
        logger.error(f"Gagal mengirimkan notifikasi WhatsApp: {e}")
        return False
