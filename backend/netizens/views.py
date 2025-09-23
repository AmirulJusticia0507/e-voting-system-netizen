from rest_framework import generics
from .serializers import NetizenSignupSerializer
from rest_framework.response import Response
from rest_framework import status

class NetizenSignupView(generics.CreateAPIView):
    serializer_class = NetizenSignupSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Signup berhasil!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
