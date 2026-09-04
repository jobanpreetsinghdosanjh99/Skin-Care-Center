class Disease {
  const Disease({
    required this.id,
    required this.shortName,
    required this.fullName,
    this.description,
  });

  final String id;
  final String shortName;
  final String fullName;
  final String? description;

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'] as String,
      shortName: json['short_name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
    );
  }
}
