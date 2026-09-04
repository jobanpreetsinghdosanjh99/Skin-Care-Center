import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../services/diseases_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

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

  void _refresh() {
    setState(() {
      _future = _api.list();
    });
  }

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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Diseases',
              subtitle: 'Maintain the clinic\'s disease reference list',
              action: FilledButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Disease'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<List<Disease>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load diseases',
                      message: '${snapshot.error}',
                    );
                  }
                  final diseases = snapshot.data ?? [];
                  if (diseases.isEmpty) {
                    return const EmptyState(
                      icon: Icons.biotech_outlined,
                      title: 'No diseases found',
                      message: 'Add a disease to build your reference list.',
                    );
                  }
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.sizeOf(context).width,
                        ),
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
                                      DataCell(
                                        Text(disease.shortName.toTitleCase),
                                      ),
                                      DataCell(
                                        Text(
                                          disease.fullName.toTitleCase,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 280,
                                          child: Text(
                                            disease.description ?? '—',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.danger,
                                          ),
                                          tooltip: 'Delete disease',
                                          onPressed: () => _delete(disease),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
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
        shortName: _shortNameController.text.trim().toTitleCase,
        fullName: _fullNameController.text.trim().toTitleCase,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim().toSentenceCase,
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
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
