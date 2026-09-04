import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../services/diseases_api.dart';

class DiseasesPage extends StatefulWidget {
  const DiseasesPage({super.key});

  @override
  State<DiseasesPage> createState() => _DiseasesPageState();
}

class _DiseasesPageState extends State<DiseasesPage> {
  final _api = DiseasesApi();
  late Future<List<Disease>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _refresh() => setState(() => _future = _api.list());

  Future<void> _openAddDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddDiseaseDialog(),
    );
    if (created == true) _refresh();
  }

  Future<void> _delete(Disease disease) async {
    await _api.delete(disease.id);
    _refresh();
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
                    Text(
                      'Diseases',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text('Manage disease records'),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Disease'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Disease>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to load diseases: ${snapshot.error}'),
                    );
                  }
                  final diseases = snapshot.data ?? [];
                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Short Name')),
                          DataColumn(label: Text('Full Name')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: diseases
                            .map(
                              (disease) => DataRow(
                                cells: [
                                  DataCell(Text(disease.shortName)),
                                  DataCell(Text(disease.fullName)),
                                  DataCell(Text(disease.description ?? '-')),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(disease),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
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

class _AddDiseaseDialog extends StatefulWidget {
  const _AddDiseaseDialog();

  @override
  State<_AddDiseaseDialog> createState() => _AddDiseaseDialogState();
}

class _AddDiseaseDialogState extends State<_AddDiseaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _shortNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await DiseasesApi().create(
        shortName: _shortNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
      title: const Text('Add New Disease'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _shortNameController,
                decoration: const InputDecoration(labelText: 'Short Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
