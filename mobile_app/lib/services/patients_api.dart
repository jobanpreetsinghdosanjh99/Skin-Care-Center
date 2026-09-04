import '../models/patient.dart';
import 'api_client.dart';

class PatientsApi {
  PatientsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Patient>> list({String? search, String searchBy = 'name'}) async {
    final query = <String, String>{'search_by': searchBy};
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await _client.get('/patients', query) as List<dynamic>;
    return data
        .map((item) => Patient.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> get(String patientId) async {
    final data = await _client.get('/patients/$patientId');
    return Patient.fromJson(data as Map<String, dynamic>);
  }

  Future<Patient> create({
    required String fullName,
    required String phone,
    int? ageYears,
    String gender = 'prefer_not_to_say',
    String? address,
  }) async {
    final data = await _client.post('/patients', {
      'full_name': fullName,
      'phone': phone,
      'age_years': ageYears,
      'gender': gender,
      'address': address,
    }, expected: 201);
    return Patient.fromJson(data as Map<String, dynamic>);
  }

  Future<Patient> update(
    String patientId, {
    required String fullName,
    required String phone,
    int? ageYears,
    String gender = 'prefer_not_to_say',
    String? address,
  }) async {
    final data = await _client.put('/patients/$patientId', {
      'full_name': fullName,
      'phone': phone,
      'age_years': ageYears,
      'gender': gender,
      'address': address,
    });
    return Patient.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String patientId) =>
      _client.delete('/patients/$patientId');
}
