class FooterNote {
  const FooterNote({
    required this.id,
    required this.note,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String note;
  final int sortOrder;
  final bool isActive;

  factory FooterNote.fromJson(Map<String, dynamic> json) {
    return FooterNote(
      id: json['id'] as String,
      note: json['note'] as String,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
    );
  }
}
