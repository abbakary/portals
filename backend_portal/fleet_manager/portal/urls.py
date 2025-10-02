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
from . import views_web

router = DefaultRouter()
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'inspectors', InspectorProfileViewSet, basename='inspector')
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'assignments', VehicleAssignmentViewSet, basename='assignment')
router.register(r'inspections', InspectionViewSet, basename='inspection')
router.register(r'categories', InspectionCategoryViewSet, basename='category')
router.register(r'checklist-items', ChecklistItemViewSet, basename='checklist-item')

urlpatterns = [
    # Web admin shell and partials (HTMX)
    path('app/', views_web.app_shell, name='portal-app'),
    path('app/customers/', views_web.customers_view, name='portal-customers'),
    path('app/vehicles/', views_web.vehicles_view, name='portal-vehicles'),
    path('app/inspectors/', views_web.inspectors_view, name='portal-inspectors'),
    path('app/assignments/', views_web.assignments_view, name='portal-assignments'),
    path('app/inspections/', views_web.inspections_view, name='portal-inspections'),
    path('app/categories/', views_web.categories_view, name='portal-categories'),

    # API
    path('auth/token/', AuthTokenView.as_view(), name='auth-token'),
    path('', include(router.urls)),
]
