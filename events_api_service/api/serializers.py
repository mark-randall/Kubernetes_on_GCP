from django.db import transaction
from django.conf import settings
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from api import models

class SessionSerializer(serializers.ModelSerializer):

    class Meta:
        model = models.Session
        ordering = ['title']
        fields = '__all__'