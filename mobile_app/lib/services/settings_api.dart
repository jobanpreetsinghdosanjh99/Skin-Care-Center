import '../models/footer_note.dart';
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
        })
        as Map<String, dynamic>;
  }

  Future<List<FooterNote>> listFooterNotes() async {
    final data = await _client.get('/settings/footer-notes') as List<dynamic>;
    return data
        .map((item) => FooterNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FooterNote> addFooterNote(String note, {int sortOrder = 0}) async {
    final data = await _client.post('/settings/footer-notes', {
      'note': note,
      'sort_order': sortOrder,
    }, expected: 201);
    return FooterNote.fromJson(data as Map<String, dynamic>);
  }

  Future<FooterNote> updateFooterNote(
    String noteId, {
    required String note,
    required int sortOrder,
    bool isActive = true,
  }) async {
    final data = await _client.put('/settings/footer-notes/$noteId', {
      'note': note,
      'sort_order': sortOrder,
      'is_active': isActive,
    });
    return FooterNote.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFooterNote(String noteId) =>
      _client.delete('/settings/footer-notes/$noteId');

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post('/settings/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    }, expected: 204);
  }
}
