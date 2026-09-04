import '../models/medicine.dart';
import 'api_client.dart';

class MedicinesApi {
  MedicinesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Medicine>> list({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final data = await _client.get('/medicines', query) as List<dynamic>;
    return data
        .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> create({
    required String name,
    required String form,
    int currentStock = 0,
  }) async {
    final data = await _client.post('/medicines', {
      'name': name,
      'form': form,
      'current_stock': currentStock,
    }, expected: 201);
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<Medicine> adjustStock(
    String medicineId,
    int quantityDelta, {
    String? note,
  }) async {
    final data = await _client.post(
      '/medicines/$medicineId/stock-adjustments',
      {'quantity_delta': quantityDelta, 'note': note},
    );
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<List<dynamic>> stockHistory(String medicineId) async {
    return await _client.get('/medicines/$medicineId/stock-movements')
        as List<dynamic>;
  }
}
