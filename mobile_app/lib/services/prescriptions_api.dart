import 'api_client.dart';

class PrescriptionsApi {
  PrescriptionsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

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
