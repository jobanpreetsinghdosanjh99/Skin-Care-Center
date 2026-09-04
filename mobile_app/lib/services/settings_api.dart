import 'api_client.dart';

class SettingsApi {
  SettingsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> getClinic() async {
    return await _client.get('/settings/clinic') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateClinic({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    return await _client.put('/settings/clinic', {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    }) as Map<String, dynamic>;
  }

  Future<List<String>> listFooterNotes() async {
    final data = await _client.get('/settings/footer-notes') as List<dynamic>;
    return data.cast<String>();
  }

  Future<void> addFooterNote(String note) async {
    await _client.post('/settings/footer-notes', {'note': note}, expected: 201);
  }
}
