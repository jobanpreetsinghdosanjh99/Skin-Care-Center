import 'api_client.dart';

/// One prescription's contribution to a sales report.
class SalesEntry {
  SalesEntry({
    required this.id,
    required this.createdAt,
    required this.patientName,
    required this.patientNumber,
    required this.amount,
    required this.itemCount,
  });

  final String id;
  final DateTime createdAt;
  final String patientName;
  final String patientNumber;
  final double amount;
  final int itemCount;

  factory SalesEntry.fromJson(Map<String, dynamic> json) => SalesEntry(
    id: '${json['id']}',
    createdAt: DateTime.parse('${json['created_at']}').toLocal(),
    patientName: '${json['patient_name'] ?? ''}',
    patientNumber: '${json['patient_number'] ?? ''}',
    amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
    itemCount: int.tryParse('${json['item_count'] ?? 0}') ?? 0,
  );
}

/// Per-day totals, used to break a multi-day range down day by day.
class SalesDay {
  SalesDay({
    required this.date,
    required this.total,
    required this.prescriptionCount,
  });

  final String date;
  final double total;
  final int prescriptionCount;

  factory SalesDay.fromJson(Map<String, dynamic> json) => SalesDay(
    date: '${json['date']}',
    total: double.tryParse('${json['total'] ?? 0}') ?? 0,
    prescriptionCount: int.tryParse('${json['prescription_count'] ?? 0}') ?? 0,
  );
}

class SalesReport {
  SalesReport({
    required this.total,
    required this.prescriptionCount,
    required this.daily,
    required this.prescriptions,
  });

  final double total;
  final int prescriptionCount;
  final List<SalesDay> daily;
  final List<SalesEntry> prescriptions;

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    total: double.tryParse('${json['total'] ?? 0}') ?? 0,
    prescriptionCount: int.tryParse('${json['prescription_count'] ?? 0}') ?? 0,
    daily: ((json['daily'] ?? []) as List<dynamic>)
        .map((e) => SalesDay.fromJson(e as Map<String, dynamic>))
        .toList(),
    prescriptions: ((json['prescriptions'] ?? []) as List<dynamic>)
        .map((e) => SalesEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ReportsApi {
  ReportsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// [from] is inclusive, [to] is exclusive — both carry a time component so
  /// a report can cover a specific time frame within a day, not just whole
  /// days.
  Future<SalesReport> sales({
    required DateTime from,
    required DateTime to,
  }) async {
    final data =
        await _client.get('/reports/sales', {
              'from': _format(from),
              'to': _format(to),
            })
            as Map<String, dynamic>;
    return SalesReport.fromJson(data);
  }

  /// Sends local wall-clock time (no timezone suffix) so the backend
  /// compares against `created_at` in the clinic's own timezone.
  static String _format(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
