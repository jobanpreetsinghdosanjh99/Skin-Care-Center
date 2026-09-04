import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicines_api.dart';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  final _api = MedicinesApi();
  final _searchController = TextEditingController();
  late Future<List<Medicine>> _future;

  static const _forms = [
    'cream',
    'soap',
    'tablet',
    'capsule',
    'lotion',
    'sunscreen',
    'face_wash',
    'serum',
    'shampoo',
    'syrup',
    'injection',
  ];

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _refresh() {
    setState(() => _future = _api.list(search: _searchController.text.trim()));
  }

  Future<void> _openAddMedicineDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddMedicineDialog(forms: _forms),
    );
    if (created == true) _refresh();
  }

  Future<void> _openAdjustStockDialog(Medicine medicine) async {
    final adjusted = await showDialog<bool>(
      context: context,
      builder: (_) => _AdjustStockDialog(medicine: medicine),
    );
    if (adjusted == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Medicines', style: Theme.of(context).textTheme.headlineMedium),
                    const Text('Manage medicine inventory'),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _openAddMedicineDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medicine'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search medicines by name...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _refresh(),
                  ),
                ),
                FilledButton(onPressed: _refresh, child: const Text('Find')),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    _refresh();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Medicine>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load medicines: ${snapshot.error}'));
                  }
                  final medicines = snapshot.data ?? [];
                  if (medicines.isEmpty) {
                    return const Center(child: Text('No medicines found.'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      medicine.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(medicine.form),
                              const Spacer(),
                              Text('Stock: ${medicine.currentStock}'),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _openAdjustStockDialog(medicine),
                                  child: const Text('Adjust Stock'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicineDialog extends StatefulWidget {
  const _AddMedicineDialog({required this.forms});

  final List<String> forms;

  @override
  State<_AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  String? _form;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await MedicinesApi().create(
        name: _nameController.text.trim(),
        form: _form!,
        currentStock: int.tryParse(_stockController.text.trim()) ?? 0,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Medicine'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _form,
                decoration: const InputDecoration(labelText: 'Type'),
                items: widget.forms
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) => setState(() => _form = value),
                validator: (v) => v == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Medicine'),
        ),
      ],
    );
  }
}

class _AdjustStockDialog extends StatefulWidget {
  const _AdjustStockDialog({required this.medicine});

  final Medicine medicine;

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  final _deltaController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final delta = int.tryParse(_deltaController.text.trim());
    if (delta == null || delta == 0) {
      setState(() => _error = 'Enter a non-zero quantity');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await MedicinesApi().adjustStock(
        widget.medicine.id,
        delta,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock — ${widget.medicine.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current stock: ${widget.medicine.currentStock}'),
          const SizedBox(height: 12),
          TextField(
            controller: _deltaController,
            decoration: const InputDecoration(
              labelText: 'Quantity change (+ add, - remove)',
            ),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
