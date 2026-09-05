class PrescriptionItem {
  const PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.quantity,
    this.instructions,
  });

  final String medicineName;
  final String dosage;
  final int quantity;
  final String? instructions;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicineName: json['medicine_name'] as String,
      dosage: json['dosage'] as String,
      quantity: json['quantity'] as int,
      instructions: json['instructions'] as String?,
    );
  }
}

class PrescriptionDisease {
  const PrescriptionDisease({
    required this.id,
    required this.shortName,
    required this.fullName,
  });

  final String id;
  final String shortName;
  final String fullName;

  factory PrescriptionDisease.fromJson(Map<String, dynamic> json) {
    return PrescriptionDisease(
      id: json['id'] as String,
      shortName: json['short_name'] as String,
      fullName: json['full_name'] as String,
    );
  }
}

class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientNumber,
    required this.status,
    this.duration,
    this.diagnosisNotes,
    this.generalInstructions,
    this.footerNote,
    required this.createdAt,
    required this.items,
    this.diseases = const [],
  });

  final String id;
  final String patientId;
  final String patientName;
  final String patientNumber;
  final String status;
  final String? duration;
  final String? diagnosisNotes;
  final String? generalInstructions;
  final String? footerNote;
  final DateTime createdAt;
  final List<PrescriptionItem> items;
  final List<PrescriptionDisease> diseases;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      patientNumber: json['patient_number'] as String? ?? '',
      status: json['status'] as String,
      duration: json['duration'] as String?,
      diagnosisNotes: json['diagnosis_notes'] as String?,
      generalInstructions: json['general_instructions'] as String?,
      footerNote: json['footer_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => PrescriptionItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      diseases: (json['diseases'] as List<dynamic>? ?? [])
          .map((d) => PrescriptionDisease.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
