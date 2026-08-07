from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet
from users.views import login_view

router = DefaultRouter()
router.register(r"", UserViewSet, basename="user")

urlpatterns = [
    path("", include(router.urls)),
    path("login/", login_view, name="login"),
]

