class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.form,
    required this.currentStock,
    this.pricePerUnit = 0,
  });

  final String id;
  final String name;
  final String form;
  final int currentStock;
  final double pricePerUnit;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      form: json['form'] as String,
      currentStock: json['current_stock'] as int,
      pricePerUnit: double.tryParse('${json['price_per_unit'] ?? 0}') ?? 0,
    );
  }
}
