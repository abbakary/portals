from __future__ import annotations

from django.db.models import Prefetch
from rest_framework import mixins, status, viewsets
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
from .permissions import (
    IsAdmin,
    IsCustomer,
    IsCustomerOrAdmin,
    IsInspector,
    IsInspectorOrAdmin,
    get_portal_profile,
)
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


class AuthTokenView(ObtainAuthToken):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _created = Token.objects.get_or_create(user=user)
        profile = get_portal_profile(user)
        profile_data = PortalUserSerializer(profile).data if profile else None
        return Response({"token": token.key, "profile": profile_data})


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.select_related("profile", "profile__user").all()
    serializer_class = CustomerSerializer
    permission_classes = [IsAuthenticated, IsAdmin]


class InspectorProfileViewSet(viewsets.ModelViewSet):
    queryset = InspectorProfile.objects.select_related("profile", "profile__user").all()
    serializer_class = InspectorProfileSerializer
    permission_classes = [IsAuthenticated, IsAdmin]


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        queryset = Vehicle.objects.select_related("customer", "customer__profile", "customer__profile__user").all()
        if not profile:
            return queryset.none()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        if profile.role == PortalUser.ROLE_CUSTOMER:
            return queryset.filter(customer=profile.customer_profile)
        if profile.role == PortalUser.ROLE_INSPECTOR:
            inspector_profile = profile.inspector_profile
            return queryset.filter(assignments__inspector=inspector_profile).distinct()
        return queryset.none()

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsAdmin()]
        return super().get_permissions()


class VehicleAssignmentViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleAssignmentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        queryset = VehicleAssignment.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        if not profile:
            return queryset.none()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        if profile.role == PortalUser.ROLE_INSPECTOR:
            return queryset.filter(inspector=profile.inspector_profile)
        return queryset.none()

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated(), IsInspectorOrAdmin()]


class InspectionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    queryset = Inspection.objects.select_related(
        "vehicle",
        "vehicle__customer",
        "vehicle__customer__profile",
        "inspector",
        "inspector__profile",
        "inspector__profile__user",
        "customer",
    ).prefetch_related(
        Prefetch(
            "item_responses",
            queryset=InspectionItemResponse.objects.select_related("checklist_item", "checklist_item__category").prefetch_related("photos"),
        )
    )

    def get_serializer_class(self):
        if self.action == "list":
            return InspectionListSerializer
        return InspectionSerializer

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        if not profile:
            return Inspection.objects.none()
        queryset = super().get_queryset()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        if profile.role == PortalUser.ROLE_INSPECTOR:
            return queryset.filter(inspector=profile.inspector_profile)
        if profile.role == PortalUser.ROLE_CUSTOMER:
            return queryset.filter(customer=profile.customer_profile)
        return queryset.none()

    def perform_create(self, serializer):
        profile = get_portal_profile(self.request.user)
        if profile and profile.role == PortalUser.ROLE_INSPECTOR:
            serializer.save(inspector=profile.inspector_profile)
        else:
            serializer.save()

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsInspectorOrAdmin])
    def submit(self, request, pk=None):
        inspection = self.get_object()
        inspection.status = Inspection.STATUS_SUBMITTED
        inspection.completed_at = inspection.completed_at or inspection.updated_at
        inspection.save(update_fields=["status", "completed_at", "updated_at"])
        generate_customer_report(inspection)
        return Response(InspectionSerializer(inspection).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsAdmin])
    def approve(self, request, pk=None):
        inspection = self.get_object()
        inspection.status = Inspection.STATUS_APPROVED
        inspection.save(update_fields=["status", "updated_at"])
        report = generate_customer_report(inspection)
        return Response({"status": inspection.status, "report": report.summary})


class InspectionCategoryViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    queryset = InspectionCategory.objects.prefetch_related("items")
    serializer_class = InspectionCategorySerializer
    permission_classes = [AllowAny]


class ChecklistItemViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ChecklistItem.objects.filter(is_active=True).select_related("category")
    serializer_class = ChecklistItemSerializer
    permission_classes = [AllowAny]
