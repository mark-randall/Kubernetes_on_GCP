from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework import renderers
from api import models
from api import serializers

class SessionViewSet(ModelViewSet):
    queryset = models.Session.objects.all()
    serializer_class = serializers.SessionSerializer