import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicines_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

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
    setState(() {
      _future = _api.list(search: _searchController.text.trim());
    });
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Medicines',
              subtitle: 'Track and manage your medicine inventory',
              action: FilledButton.icon(
                onPressed: _openAddMedicineDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Medicine'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search medicines by name...',
                        ),
                        onSubmitted: (_) => _refresh(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Find'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        _refresh();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<List<Medicine>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load medicines',
                      message: '${snapshot.error}',
                    );
                  }
                  final medicines = snapshot.data ?? [];
                  if (medicines.isEmpty) {
                    return const EmptyState(
                      icon: Icons.medication_outlined,
                      title: 'No medicines found',
                      message: 'Add a medicine to start tracking inventory.',
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.25,
                        ),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return _MedicineCard(
                        medicine: medicine,
                        onAdjustStock: () => _openAdjustStockDialog(medicine),
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

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, required this.onAdjustStock});

  final Medicine medicine;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    final stock = medicine.currentStock;
    final Color stockColor = stock <= 0
        ? AppTheme.danger
        : stock <= 10
        ? AppTheme.warning
        : AppTheme.success;
    final String stockLabel = stock <= 0
        ? 'Out of Stock'
        : stock <= 10
        ? 'Low Stock'
        : 'In Stock';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(text: medicine.name, icon: Icons.medication),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medicine.name.toTitleCase,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              medicine.form.toTitleCase,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock: $stock',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                StatusPill(label: stockLabel, color: stockColor),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAdjustStock,
                child: const Text('Adjust Stock'),
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
        name: _nameController.text.trim().toTitleCase,
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
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _form,
                decoration: const InputDecoration(labelText: 'Type'),
                items: widget.forms
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.toTitleCase),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _form = value),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim().toSentenceCase,
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
      title: Text('Adjust Stock — ${widget.medicine.name.toTitleCase}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current stock: ${widget.medicine.currentStock}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _deltaController,
              decoration: const InputDecoration(
                labelText: 'Quantity change (+ add, - remove)',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
