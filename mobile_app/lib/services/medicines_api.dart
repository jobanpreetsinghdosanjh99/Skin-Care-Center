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
    double pricePerUnit = 0,
  }) async {
    final data = await _client.post('/medicines', {
      'name': name,
      'form': form,
      'current_stock': currentStock,
      'price_per_unit': pricePerUnit,
    }, expected: 201);
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<Medicine> update(
    String medicineId, {
    required String name,
    required String form,
    double pricePerUnit = 0,
  }) async {
    final data = await _client.put('/medicines/$medicineId', {
      'name': name,
      'form': form,
      'price_per_unit': pricePerUnit,
    });
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String medicineId) =>
      _client.delete('/medicines/$medicineId');

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
