from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NotificationViewSet, BroadcastViewSet

router = DefaultRouter()
router.register("", NotificationViewSet, basename="notification")


def include_broadcast():
    br = DefaultRouter()
    br.register("", BroadcastViewSet, basename="broadcast")
    return include(br.urls)


urlpatterns = [
    path("", include(router.urls)),
    path("broadcasts/", include_broadcast()),
]