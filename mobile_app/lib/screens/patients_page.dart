import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/patients_api.dart';

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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patients', style: Theme.of(context).textTheme.headlineMedium),
                    const Text('Manage patient information'),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _openAddPatientDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Patient'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                DropdownButton<String>(
                  value: _searchBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'phone', child: Text('Mobile')),
                    DropdownMenuItem(
                      value: 'patient_number',
                      child: Text('Patient Number'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _searchBy = value ?? 'name'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search patients...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _refresh(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _refresh, child: const Text('Search')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _clearSearch, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Patient>>(
                future: _patientsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load patients: ${snapshot.error}'));
                  }
                  final patients = snapshot.data ?? [];
                  if (patients.isEmpty) {
                    return const Center(child: Text('No patients found.'));
                  }
                  return Card(
                    child: ListView.separated(
                      itemCount: patients.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(patient.fullName[0])),
                          title: Text(patient.fullName),
                          subtitle: Text(
                            '${patient.ageYears ?? '-'} yrs • ${patient.gender} • ${patient.phone}',
                          ),
                          trailing: Text(patient.patientNumber),
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
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        ageYears: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'male'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
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
              : const Text('Add Patient'),
        ),
      ],
    );
  }
}
