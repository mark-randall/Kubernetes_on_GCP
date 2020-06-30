from django.urls import path
from django.conf.urls import include, url
from rest_framework import routers
from api import views

router = routers.DefaultRouter(trailing_slash=False)

router.register('sessions', views.SessionViewSet)

urlpatterns = router.urls