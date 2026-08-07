from django.urls import path
from channels.routing import URLRouter

from .consumers import VoteStreamConsumer

websocket_urlpatterns = [
    path("ws/votes/<int:topic_id>/", VoteStreamConsumer.as_asgi()),
]