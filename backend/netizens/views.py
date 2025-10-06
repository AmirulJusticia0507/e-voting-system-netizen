# netizens/views.py
from rest_framework import generics, status
from .serializers import NetizenSignupSerializer
from rest_framework.response import Response

class NetizenSignupView(generics.CreateAPIView):
    serializer_class = NetizenSignupSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {"message": "Signup berhasil!", "user_id": user.id},
            status=status.HTTP_201_CREATED
        )
