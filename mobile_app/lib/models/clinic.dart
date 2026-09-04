class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.prescriptionFooterNote,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? prescriptionFooterNote;
  final bool isActive;

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      prescriptionFooterNote: json['prescription_footer_note'] as String?,
      isActive: json['is_active'] as bool,
    );
  }
}
