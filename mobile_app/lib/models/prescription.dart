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

class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.status,
    this.duration,
    this.diagnosisNotes,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String patientId;
  final String status;
  final String? duration;
  final String? diagnosisNotes;
  final DateTime createdAt;
  final List<PrescriptionItem> items;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      status: json['status'] as String,
      duration: json['duration'] as String?,
      diagnosisNotes: json['diagnosis_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => PrescriptionItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
