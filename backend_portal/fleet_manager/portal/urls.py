from django.urls import include, path
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AuthTokenView,
    ChecklistItemViewSet,
    CustomerViewSet,
    InspectionCategoryViewSet,
    InspectionViewSet,
    InspectorProfileViewSet,
    VehicleAssignmentViewSet,
    VehicleViewSet,
)

router = DefaultRouter()
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'inspectors', InspectorProfileViewSet, basename='inspector')
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'assignments', VehicleAssignmentViewSet, basename='assignment')
router.register(r'inspections', InspectionViewSet, basename='inspection')
router.register(r'categories', InspectionCategoryViewSet, basename='category')
router.register(r'checklist-items', ChecklistItemViewSet, basename='checklist-item')

urlpatterns = [
    path('auth/token/', AuthTokenView.as_view(), name='auth-token'),
    path('', include(router.urls)),
]
