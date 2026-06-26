from django.urls import path, include
from rest_framework.routers import DefaultRouter
from api.views import StopViewSet, RouteViewSet, SearchView, JourneyView, JourneyDetailView

router = DefaultRouter()
router.register(r'stops', StopViewSet, basename='stop')
router.register(r'routes', RouteViewSet, basename='route')

urlpatterns = [
    path('', include(router.urls)),
    path('search/', SearchView.as_view(), name='api-search'),
    path('journey/', JourneyView.as_view(), name='api-journey'),
    path('journey/<int:pk>/', JourneyDetailView.as_view(), name='api-journey-detail'),
]
