import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../services/clinic_scope.dart';
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
  final _shortNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  late Future<List<Disease>> _future;
  int _page = 1;
  int _pageSize = 10;
  int _lastPageCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
    ClinicScope.epoch.addListener(_refresh);
  }

  @override
  void dispose() {
    ClinicScope.epoch.removeListener(_refresh);
    super.dispose();
  }

  Future<List<Disease>> _load() async {
    final results = await _api.list(
      shortName: _shortNameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      page: _page,
      pageSize: _pageSize,
    );
    _lastPageCount = results.length;
    return results;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _search() {
    _page = 1;
    _refresh();
  }

  void _clearSearch() {
    _shortNameController.clear();
    _fullNameController.clear();
    _page = 1;
    _refresh();
  }

  void _goToPage(int page) {
    if (page < 1) return;
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  void _changePageSize(int size) {
    setState(() {
      _pageSize = size;
      _page = 1;
      _future = _load();
    });
  }

  Future<void> _openAddDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddDiseaseDialog(),
    );
    if (created == true) _refresh();
  }

  Future<void> _openEditDialog(Disease disease) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _AddDiseaseDialog(disease: disease),
    );
    if (updated == true) _refresh();
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _shortNameController,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search short name...',
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search full name...',
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _search,
                      child: const Text('Search'),
                    ),
                    OutlinedButton(
                      onPressed: _clearSearch,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Show:'),
                    DropdownButton<int>(
                      value: _pageSize,
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                      ],
                      onChanged: (value) => _changePageSize(value ?? 10),
                    ),
                    const Text('per page'),
                  ],
                ),
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
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: AppTheme.primary,
                                              ),
                                              tooltip: 'Edit disease',
                                              onPressed: () =>
                                                  _openEditDialog(disease),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppTheme.danger,
                                              ),
                                              tooltip: 'Delete disease',
                                              onPressed: () => _delete(disease),
                                            ),
                                          ],
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing $_lastPageCount item${_lastPageCount == 1 ? '' : 's'} on page $_page',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous',
                    ),
                    Text('Page $_page'),
                    IconButton(
                      onPressed: _lastPageCount >= _pageSize
                          ? () => _goToPage(_page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDiseaseDialog extends StatefulWidget {
  const _AddDiseaseDialog({this.disease});

  final Disease? disease;

  @override
  State<_AddDiseaseDialog> createState() => _AddDiseaseDialogState();
}

class _AddDiseaseDialogState extends State<_AddDiseaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _shortNameController = TextEditingController(
    text: widget.disease?.shortName ?? '',
  );
  late final _fullNameController = TextEditingController(
    text: widget.disease?.fullName ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.disease?.description ?? '',
  );
  bool _submitting = false;
  String? _error;
  bool get _isEditing => widget.disease != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await DiseasesApi().update(
          widget.disease!.id,
          shortName: _shortNameController.text.trim().toTitleCase,
          fullName: _fullNameController.text.trim().toTitleCase,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim().toSentenceCase,
        );
      } else {
        await DiseasesApi().create(
          shortName: _shortNameController.text.trim().toTitleCase,
          fullName: _fullNameController.text.trim().toTitleCase,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim().toSentenceCase,
        );
      }
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
      title: Text(_isEditing ? 'Edit Disease' : 'Add New Disease'),
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
