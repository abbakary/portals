from __future__ import annotations

from django.db.models import Prefetch
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken

from .models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectionItemResponse,
    InspectorProfile,
    PortalUser,
    Vehicle,
    VehicleAssignment,
)
from .permissions import IsAdmin, IsInspectorOrAdmin, get_portal_profile
from .serializers import (
    ChecklistItemSerializer,
    CustomerSerializer,
    InspectionCategorySerializer,
    InspectionListSerializer,
    InspectionSerializer,
    InspectorProfileSerializer,
    PortalUserSerializer,
    VehicleAssignmentSerializer,
    VehicleSerializer,
)
from .services import generate_customer_report
