from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RegionViewSet, ElectionPeriodViewSet

router = DefaultRouter()
router.register("regions", RegionViewSet, basename="region")
router.register("", ElectionPeriodViewSet, basename="election")

urlpatterns = [
    path("", include(router.urls)),
]