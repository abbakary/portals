from __future__ import annotations

from django import forms

from .models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectorProfile,
    Vehicle,
    VehicleAssignment,
)


class BaseForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            css = field.widget.attrs.get("class", "").strip()
            base = "input"
            if isinstance(field.widget, (forms.Textarea,)):
                base = "textarea"
            elif isinstance(field.widget, (forms.Select, forms.SelectMultiple)):
                base = "select"
            field.widget.attrs["class"] = (css + " " + base).strip()


class CustomerForm(BaseForm):
    class Meta:
        model = Customer
        fields = [
            "profile",
            "legal_name",
            "contact_email",
            "contact_phone",
            "address_line1",
            "address_line2",
            "city",
            "state",
            "postal_code",
            "country",
            "notes",
        ]


class InspectorProfileForm(BaseForm):
    class Meta:
        model = InspectorProfile
        fields = [
            "profile",
            "badge_id",
            "certifications",
            "is_active",
            "max_daily_inspections",
        ]


class VehicleForm(BaseForm):
    class Meta:
        model = Vehicle
        fields = [
            "customer",
            "vin",
            "license_plate",
            "make",
            "model",
            "year",
            "vehicle_type",
            "axle_configuration",
            "mileage",
            "notes",
        ]


class VehicleAssignmentForm(BaseForm):
    scheduled_for = forms.DateField(widget=forms.DateInput(attrs={"type": "date"}))

    class Meta:
        model = VehicleAssignment
        fields = [
            "vehicle",
            "inspector",
            "scheduled_for",
            "status",
            "remarks",
        ]


class InspectionForm(BaseForm):
    started_at = forms.DateTimeField(required=False, widget=forms.DateTimeInput(attrs={"type": "datetime-local"}))
    completed_at = forms.DateTimeField(required=False, widget=forms.DateTimeInput(attrs={"type": "datetime-local"}))

    class Meta:
        model = Inspection
        fields = [
            "assignment",
            "vehicle",
            "customer",
            "inspector",
            "status",
            "started_at",
            "completed_at",
            "odometer_reading",
            "general_notes",
        ]


class InspectionCategoryForm(BaseForm):
    class Meta:
        model = InspectionCategory
        fields = [
            "code",
            "name",
            "description",
            "display_order",
        ]


class ChecklistItemForm(BaseForm):
    class Meta:
        model = ChecklistItem
        fields = [
            "category",
            "code",
            "title",
            "description",
            "requires_photo",
            "is_active",
        ]
