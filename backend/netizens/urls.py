from django.urls import path
from .views import NetizenSignupView

urlpatterns = [
    path('signup/', NetizenSignupView.as_view(), name='netizen-signup'),
]
