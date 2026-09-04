import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/patients_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _api = PatientsApi();
  final _searchController = TextEditingController();
  String _searchBy = 'name';

  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _api.list();
  }

  void _refresh() {
    setState(() {
      _patientsFuture = _api.list(
        search: _searchController.text.trim(),
        searchBy: _searchBy,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _refresh();
  }

  Future<void> _openAddPatientDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddPatientDialog(),
    );
    if (created == true) _refresh();
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
              title: 'Patients',
              subtitle: 'Manage patient information and records',
              action: FilledButton.icon(
                onPressed: _openAddPatientDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Patient'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchBar(
              searchBy: _searchBy,
              controller: _searchController,
              onSearchByChanged: (value) =>
                  setState(() => _searchBy = value ?? 'name'),
              onSearch: _refresh,
              onClear: _clearSearch,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<List<Patient>>(
                future: _patientsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load patients',
                      message: '${snapshot.error}',
                    );
                  }
                  final patients = snapshot.data ?? [];
                  if (patients.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No patients found',
                      message: 'Try a different search or add a new patient.',
                    );
                  }
                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: patients.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: InitialsAvatar(text: patient.fullName),
                          title: Text(
                            patient.fullName.toTitleCase,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${patient.ageYears ?? '-'} yrs • '
                            '${patient.gender.toTitleCase} • ${patient.phone}',
                          ),
                          trailing: StatusPill(
                            label: patient.patientNumber,
                            color: AppTheme.primary,
                          ),
                        );
                      },
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.searchBy,
    required this.controller,
    required this.onSearchByChanged,
    required this.onSearch,
    required this.onClear,
  });

  final String searchBy;
  final TextEditingController controller;
  final ValueChanged<String?> onSearchByChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: searchBy,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Search by',
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'phone', child: Text('Mobile')),
                  DropdownMenuItem(
                    value: 'patient_number',
                    child: Text('Patient Number'),
                  ),
                ],
                onChanged: onSearchByChanged,
              ),
            ),
            SizedBox(
              width: 280,
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search patients...',
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            FilledButton(onPressed: onSearch, child: const Text('Search')),
            OutlinedButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

class _AddPatientDialog extends StatefulWidget {
  const _AddPatientDialog();

  @override
  State<_AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<_AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'male';
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await PatientsApi().create(
        fullName: _nameController.text.trim().toTitleCase,
        phone: _phoneController.text.trim(),
        ageYears: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim().toSentenceCase,
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
      title: const Text('Add New Patient'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'male'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                textCapitalization: TextCapitalization.sentences,
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
              : const Text('Add Patient'),
        ),
      ],
    );
  }
}
