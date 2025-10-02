from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from django.http import HttpRequest, HttpResponse

from .models import Customer, Vehicle, InspectorProfile, VehicleAssignment, Inspection, InspectionCategory
from .permissions import get_portal_profile, PortalUser


def _require_admin(request: HttpRequest) -> PortalUser | None:
    user = request.user
    if not user.is_authenticated:
        return None
    profile = get_portal_profile(user)
    if not profile or profile.role != PortalUser.ROLE_ADMIN:
        return None
    return profile


@login_required
def app_shell(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    context = {
        "profile": profile,
        "kpi_customers": Customer.objects.count(),
        "kpi_vehicles": Vehicle.objects.count(),
        "kpi_inspectors": InspectorProfile.objects.count(),
        "kpi_inspections": Inspection.objects.count(),
    }
    return render(request, "portal/dashboard.html", context)


@login_required
def customers_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    customers = Customer.objects.select_related("profile", "profile__user").order_by("-id")[:200]
    return render(request, "portal/partials/customers.html", {"customers": customers})


@login_required
def vehicles_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    vehicles = Vehicle.objects.select_related("customer").order_by("-id")[:200]
    return render(request, "portal/partials/vehicles.html", {"vehicles": vehicles})


@login_required
def inspectors_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspectors = InspectorProfile.objects.select_related("profile", "profile__user").order_by("-id")[:200]
    return render(request, "portal/partials/inspectors.html", {"inspectors": inspectors})


@login_required
def assignments_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    assignments = (
        VehicleAssignment.objects.select_related(
            "vehicle", "vehicle__customer", "inspector", "inspector__profile", "inspector__profile__user"
        )
        .order_by("-scheduled_for")[:200]
    )
    return render(request, "portal/partials/assignments.html", {"assignments": assignments})


@login_required
def inspections_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspections = (
        Inspection.objects.select_related(
            "vehicle", "vehicle__customer", "inspector", "inspector__profile", "inspector__profile__user"
        )
        .order_by("-created_at")[:200]
    )
    return render(request, "portal/partials/inspections.html", {"inspections": inspections})


@login_required
def categories_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    categories = InspectionCategory.objects.prefetch_related("items").order_by("display_order")
    return render(request, "portal/partials/categories.html", {"categories": categories})
