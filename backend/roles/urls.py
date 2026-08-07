from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RoleViewSet, PermissionViewSet

router = DefaultRouter()
router.register("permissions", PermissionViewSet, basename="permission")
router.register("", RoleViewSet, basename="role")

urlpatterns = [
    path("", include(router.urls)),
]