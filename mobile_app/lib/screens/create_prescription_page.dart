import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/patient.dart';
import '../services/medicines_api.dart';
import '../services/patients_api.dart';
import '../services/prescriptions_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

class PrescriptionItemDraft {
  PrescriptionItemDraft({
    this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.quantity,
    this.instructions,
  });

  final String? medicineId;
  final String medicineName;
  final String dosage;
  final int quantity;
  final String? instructions;
}

class CreatePrescriptionPage extends StatefulWidget {
  const CreatePrescriptionPage({super.key, this.preselectedPatient});

  final Patient? preselectedPatient;

  @override
  State<CreatePrescriptionPage> createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final _patientsApi = PatientsApi();
  final _medicinesApi = MedicinesApi();
  final _prescriptionsApi = PrescriptionsApi();

  final _patientSearchController = TextEditingController();
  Patient? _selectedPatient;
  List<Patient> _patientResults = [];

  String? _duration;
  bool _customDuration = false;
  final _customDurationController = TextEditingController();
  String? _dosagePreset;
  bool _customDosage = false;
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _instructionsController = TextEditingController();
  Medicine? _selectedMedicine;
  List<Medicine> _medicineOptions = [];

  final _items = <PrescriptionItemDraft>[];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.preselectedPatient;
  }

  static const _durations = [
    '10 days',
    '15 days',
    '20 days',
    '7 days',
    '1 month',
    'weekly',
    'Custom',
  ];

  static const _dosagePresets = [
    '0-0-1 (Night)',
    '1-0-0 (Morning)',
    '1-1-1 (Thrice a Day)',
    '1-0-1 (Alternate Day)',
    'Custom',
  ];

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _patientResults = []);
      return;
    }
    final results = await _patientsApi.list(search: query, searchBy: 'name');
    setState(() => _patientResults = results);
  }

  Future<void> _searchMedicines(String query) async {
    final results = await _medicinesApi.list(search: query);
    setState(() => _medicineOptions = results);
  }

  void _addItem() {
    if (_selectedMedicine == null || _dosageController.text.trim().isEmpty) {
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0) return;

    setState(() {
      _items.add(
        PrescriptionItemDraft(
          medicineId: _selectedMedicine!.id,
          medicineName: _selectedMedicine!.name,
          dosage: _dosageController.text.trim(),
          quantity: quantity,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim().toSentenceCase,
        ),
      );
      _selectedMedicine = null;
      _dosageController.clear();
      _dosagePreset = null;
      _customDosage = false;
      _quantityController.text = '1';
      _instructionsController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _openPrescriptionsListDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Prescriptions'),
        content: SizedBox(
          width: 480,
          height: 420,
          child: FutureBuilder(
            future: _prescriptionsApi.list(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoader();
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load prescriptions',
                  message: '${snapshot.error}',
                );
              }
              final prescriptions = snapshot.data ?? [];
              if (prescriptions.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No prescriptions yet',
                );
              }
              return ListView.separated(
                itemCount: prescriptions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prescription = prescriptions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.description, size: 18),
                    ),
                    title: Text(
                      '${prescription.items.length} item(s)'
                      '${prescription.duration != null ? ' • ${prescription.duration}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${prescription.createdAt.day.toString().padLeft(2, '0')}/'
                      '${prescription.createdAt.month.toString().padLeft(2, '0')}/'
                      '${prescription.createdAt.year} • ${prescription.status.toTitleCase}',
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String? get _effectiveDuration =>
      _customDuration ? _customDurationController.text.trim() : _duration;

  Future<void> _savePrescription() async {
    if (_selectedPatient == null || _items.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _prescriptionsApi.create(
        patientId: _selectedPatient!.id,
        duration: _effectiveDuration,
        items: _items
            .map(
              (item) => {
                'medicine_id': item.medicineId,
                'medicine_name': item.medicineName,
                'dosage': item.dosage,
                'quantity': item.quantity,
                'instructions': item.instructions,
              },
            )
            .toList(),
      );
      if (mounted) {
        setState(() {
          _items.clear();
          _selectedPatient = null;
          _patientSearchController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Create Prescription',
              subtitle: 'Search a patient, then add medicines to prescribe',
              action: OutlinedButton.icon(
                onPressed: _openPrescriptionsListDialog,
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('View All Prescriptions'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedPatient != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(text: _selectedPatient!.fullName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPatient!.fullName.toTitleCase,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedPatient!.patientNumber} • ${_selectedPatient!.phone}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedPatient = null),
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _patientSearchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search patient by name...',
                        ),
                        onChanged: _searchPatients,
                      ),
                      if (_patientResults.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: _patientResults
                                .map(
                                  (patient) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: InitialsAvatar(
                                      text: patient.fullName,
                                    ),
                                    title: Text(patient.fullName.toTitleCase),
                                    subtitle: Text(
                                      '${patient.patientNumber} • ${patient.phone}',
                                    ),
                                    onTap: () => setState(() {
                                      _selectedPatient = patient;
                                      _patientResults = [];
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medication_rounded,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Medicine',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _duration,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Prescription Duration',
                      ),
                      items: _durations
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d == 'Custom' ? d : d.toTitleCase),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _duration = value;
                        _customDuration = value == 'Custom';
                      }),
                    ),
                    if (_customDuration) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _customDurationController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Duration',
                          hintText: 'e.g. 3 weeks',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Autocomplete<Medicine>(
                      displayStringForOption: (m) => m.name.toTitleCase,
                      optionsBuilder: (value) async {
                        await _searchMedicines(value.text);
                        return _medicineOptions;
                      },
                      onSelected: (medicine) =>
                          setState(() => _selectedMedicine = medicine),
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmit) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Medicine',
                                prefixIcon: Icon(Icons.search),
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _dosagePreset,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Dosage'),
                      items: _dosagePresets
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _dosagePreset = value;
                        _customDosage = value == 'Custom';
                        _dosageController.text = _customDosage
                            ? ''
                            : (value ?? '');
                      }),
                    ),
                    if (_customDosage) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Dosage',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (optional)',
                        hintText: 'e.g. Apply twice daily',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _selectedMedicine == null ? null : _addItem,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add to Prescription'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Prescription Items (${_items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_items.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No items added yet',
                message: 'Search a medicine above and add it to the list.',
              )
            else
              Column(
                children: _items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.medication, size: 18),
                      ),
                      title: Text(
                        item.medicineName.toTitleCase,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${item.dosage} • Qty: ${item.quantity}'
                        '${item.instructions != null ? ' • ${item.instructions}' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.danger,
                        ),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (_selectedPatient == null || _items.isEmpty || _saving)
                    ? null
                    : _savePrescription,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save Prescription'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
