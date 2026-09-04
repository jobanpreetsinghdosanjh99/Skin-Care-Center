class Patient {
  const Patient({
    required this.id,
    required this.patientNumber,
    required this.fullName,
    required this.gender,
    required this.phone,
    this.ageYears,
    this.address,
    required this.createdAt,
  });

  final String id;
  final String patientNumber;
  final String fullName;
  final int? ageYears;
  final String gender;
  final String phone;
  final String? address;
  final DateTime createdAt;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      patientNumber: json['patient_number'] as String,
      fullName: json['full_name'] as String,
      ageYears: json['age_years'] as int?,
      gender: json['gender'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
