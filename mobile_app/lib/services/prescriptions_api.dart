import '../models/prescription.dart';
import 'api_client.dart';

class PrescriptionsApi {
  PrescriptionsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Prescription>> list({String? patientId}) async {
    final query = <String, String>{};
    if (patientId != null && patientId.isNotEmpty) {
      query['patient_id'] = patientId;
    }
    final data = await _client.get('/prescriptions', query) as List<dynamic>;
    return data
        .map((item) => Prescription.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> create({
    required String patientId,
    String? duration,
    String? diagnosisNotes,
    required List<Map<String, dynamic>> items,
  }) {
    return _client.post('/prescriptions', {
      'patient_id': patientId,
      'duration': duration,
      'diagnosis_notes': diagnosisNotes,
      'items': items,
    }, expected: 201);
  }
}
