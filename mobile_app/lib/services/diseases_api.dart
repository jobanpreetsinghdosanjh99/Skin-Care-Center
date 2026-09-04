import '../models/disease.dart';
import 'api_client.dart';

class DiseasesApi {
  DiseasesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Disease>> list({
    String? shortName,
    String? fullName,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, String>{'page': '$page', 'page_size': '$pageSize'};
    if (shortName != null && shortName.isNotEmpty) {
      query['short_name'] = shortName;
    }
    if (fullName != null && fullName.isNotEmpty) query['full_name'] = fullName;
    final data = await _client.get('/diseases', query) as List<dynamic>;
    return data
        .map((item) => Disease.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Disease> create({
    required String shortName,
    required String fullName,
    String? description,
  }) async {
    final data = await _client.post('/diseases', {
      'short_name': shortName,
      'full_name': fullName,
      'description': description,
    }, expected: 201);
    return Disease.fromJson(data as Map<String, dynamic>);
  }

  Future<Disease> update(
    String diseaseId, {
    required String shortName,
    required String fullName,
    String? description,
  }) async {
    final data = await _client.put('/diseases/$diseaseId', {
      'short_name': shortName,
      'full_name': fullName,
      'description': description,
    });
    return Disease.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String diseaseId) =>
      _client.delete('/diseases/$diseaseId');
}
