"""Consumer WebSocket untuk live hasil voting.

Endpoint: ``ws/votes/<topic_id>/``
Klien terhubung → dapat snapshot; setiap suara baru → dapat update.
Jalankan server dengan ``daphne`` (bukan runserver WSGI) agar websocket aktif.
"""
import json

from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async

from .results import topic_results


class VoteStreamConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.topic_id = int(self.scope["url_route"]["kwargs"].get("topic_id", 0))
        self.group_name = f"vote_topic_{self.topic_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self._send_snapshot()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def _send_snapshot(self):
        data = await self._load()
        await self.send(text_data=data)

    @database_sync_to_async
    def _load(self):
        import json
        return json.dumps({"type": "snapshot", "data": topic_results(self.topic_id)})

    async def vote_update(self, event):
        # dipicu dari broadcast di votes/signals.py
        await self.send(text_data=event["data"])