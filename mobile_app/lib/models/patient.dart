class Patient {
  const Patient({
    required this.id,
    required this.patientNumber,
    required this.fullName,
    required this.gender,
    required this.phone,
    this.ageYears,
    this.ageMonths,
    this.address,
    required this.createdAt,
  });

  final String id;
  final String patientNumber;
  final String fullName;
  final int? ageYears;
  final int? ageMonths;
  final String gender;
  final String phone;
  final String? address;
  final DateTime createdAt;

  /// Human-readable age like "5 yrs 3 mo", "8 mo", or "-" when unknown.
  String get ageLabel {
    final parts = <String>[
      if (ageYears != null && ageYears! > 0) '$ageYears yrs',
      if (ageMonths != null && ageMonths! > 0) '$ageMonths mo',
    ];
    if (parts.isEmpty) {
      return (ageYears != null || ageMonths != null) ? '0 mo' : '-';
    }
    return parts.join(' ');
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      patientNumber: json['patient_number'] as String,
      fullName: json['full_name'] as String,
      ageYears: json['age_years'] as int?,
      ageMonths: json['age_months'] as int?,
      gender: json['gender'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
