"""Broadcast real-time saat ada suara baru (best-effort; tetap aman bila Redis off)."""
import json
import logging

from django.conf import settings
from django.db.models.signals import post_save

logger = logging.getLogger(__name__)


def broadcast_vote(instance):
    """Kirim hasil terbaru ke semua klien WebSocket topik tersebut."""
    try:
        if not getattr(settings, "VOTE_BROADCAST", True):
            return
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync
        from .results import topic_results

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        payload = json.dumps({"type": "update", "data": topic_results(instance.topic_id)})
        async_to_sync(channel_layer.group_send)(
            f"vote_topic_{instance.topic_id}",
            {"type": "vote_update", "data": payload},
        )
    except Exception as e:
        # Redis/channels belum jalan → abaikan, REST tetap bekerja.
        logger.warning(f"Broadcast live gagal (lanjut tanpa realtime): {e}")


def register_signals():
    from .models import Vote

    def handler(sender, instance, **kwargs):
        if kwargs.get("created"):
            broadcast_vote(instance)

    post_save.connect(handler, sender=Vote, dispatch_uid="votes_broadcast_save")