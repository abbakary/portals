class PortalProfile {
  const PortalProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.organization,
  });

  final int id;
  final String role;
  final String fullName;
  final String organization;

  factory PortalProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final fullName = (('$firstName $lastName').trim().isEmpty ? username : '$firstName $lastName').trim();
    return PortalProfile(
      id: json['id'] as int,
      role: json['role'] as String,
      fullName: fullName,
      organization: json['organization'] as String? ?? '',
    );
  }
}

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.mileage,
  });

  final int id;
  final String licensePlate;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String vehicleType;
  final int mileage;

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as int,
        licensePlate: json['license_plate'] as String,
        vin: json['vin'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        vehicleType: json['vehicle_type'] as String,
        mileage: json['mileage'] as int? ?? 0,
      );
}

class ChecklistItemModel {
  const ChecklistItemModel({
    required this.id,
    required this.categoryName,
    required this.code,
    required this.title,
    required this.description,
    required this.requiresPhoto,
  });

  final int id;
  final String categoryName;
  final String code;
  final String title;
  final String description;
  final bool requiresPhoto;

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) => ChecklistItemModel(
        id: json['id'] as int,
        categoryName: json['category_name'] as String? ?? '',
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        requiresPhoto: json['requires_photo'] as bool? ?? false,
      );
}

class InspectionItemModel {
  const InspectionItemModel({
    required this.checklistItemId,
    required this.result,
    required this.severity,
    required this.notes,
    this.photoUris = const <String>[],
  });

  final int checklistItemId;
  final String result;
  final int severity;
  final String notes;
  final List<String> photoUris;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checklist_item': checklistItemId,
        'result': result,
        'severity': severity,
        'notes': notes,
      };
}

class InspectionDraftModel {
  InspectionDraftModel({
    required this.vehicleId,
    required this.inspectorId,
    required this.odometerReading,
    required this.generalNotes,
    required this.items,
    this.assignmentId,
  });

  final int? assignmentId;
  final int vehicleId;
  final int inspectorId;
  final int odometerReading;
  final String generalNotes;
  final List<InspectionItemModel> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (assignmentId != null) 'assignment': assignmentId,
        'vehicle': vehicleId,
        'inspector': inspectorId,
        'status': 'in_progress',
        'odometer_reading': odometerReading,
        'general_notes': generalNotes,
        'item_responses': items.map((item) => item.toJson()).toList(),
      };
}

class InspectionSummaryModel {
  const InspectionSummaryModel({
    required this.reference,
    required this.vehicle,
    required this.status,
    required this.createdAt,
  });

  final String reference;
  final VehicleModel vehicle;
  final String status;
  final DateTime createdAt;

  factory InspectionSummaryModel.fromJson(Map<String, dynamic> json) => InspectionSummaryModel(
        reference: json['reference'] as String,
        vehicle: VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
