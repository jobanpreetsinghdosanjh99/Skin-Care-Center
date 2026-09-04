import '../models/clinic.dart';
import 'api_client.dart';

class ClinicsApi {
  ClinicsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Clinic> getActive() async {
    final data = await _client.get('/clinics/active');
    return Clinic.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> list() async {
    final data = await _client.get('/clinics') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final data = await _client.post('/clinics', {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    }, expected: 201);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> activate(String clinicId) async {
    final data = await _client.post('/clinics/$clinicId/activate', {});
    return data as Map<String, dynamic>;
  }
}
