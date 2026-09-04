import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/patient.dart';
import '../services/medicines_api.dart';
import '../services/patients_api.dart';
import '../services/prescriptions_api.dart';

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
  const CreatePrescriptionPage({super.key});

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
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _instructionsController = TextEditingController();
  Medicine? _selectedMedicine;
  List<Medicine> _medicineOptions = [];

  final _items = <PrescriptionItemDraft>[];
  bool _saving = false;
  String? _error;

  static const _durations = ['10 days', '15 days', '20 days', '7 days', '1 month', 'weekly'];

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
    if (_selectedMedicine == null || _dosageController.text.trim().isEmpty) return;
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
              : _instructionsController.text.trim(),
        ),
      );
      _selectedMedicine = null;
      _dosageController.clear();
      _quantityController.text = '1';
      _instructionsController.clear();
    });
  }

  Future<void> _savePrescription() async {
    if (_selectedPatient == null || _items.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _prescriptionsApi.create(
        patientId: _selectedPatient!.id,
        duration: _duration,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prescription saved')));
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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Prescription', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_selectedPatient != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person),
                        title: Text(_selectedPatient!.fullName),
                        subtitle: Text(
                          '${_selectedPatient!.patientNumber} • ${_selectedPatient!.phone}',
                        ),
                        trailing: TextButton(
                          onPressed: () => setState(() => _selectedPatient = null),
                          child: const Text('Change'),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _patientSearchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search patient by name...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _searchPatients,
                      ),
                      ..._patientResults.map(
                        (patient) => ListTile(
                          title: Text(patient.fullName),
                          subtitle: Text('${patient.patientNumber} • ${patient.phone}'),
                          onTap: () => setState(() {
                            _selectedPatient = patient;
                            _patientResults = [];
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _duration,
                      decoration: const InputDecoration(labelText: 'Prescription Duration'),
                      items: _durations
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (value) => setState(() => _duration = value),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Medicine>(
                      displayStringForOption: (m) => m.name,
                      optionsBuilder: (value) async {
                        await _searchMedicines(value.text);
                        return _medicineOptions;
                      },
                      onSelected: (medicine) => setState(() => _selectedMedicine = medicine),
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Medicine'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dosageController,
                      decoration: const InputDecoration(labelText: 'Dosage'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (optional)',
                        hintText: 'e.g. Apply twice daily',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _selectedMedicine == null ? null : _addItem,
                      child: const Text('Add to Prescription'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Prescription Items', style: Theme.of(context).textTheme.titleMedium),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No items added yet.'),
              )
            else
              Column(
                children: _items
                    .map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.medicineName),
                          subtitle: Text('${item.dosage} • Qty: ${item.quantity}'),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: (_selectedPatient == null || _items.isEmpty || _saving)
                  ? null
                  : _savePrescription,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Prescription'),
            ),
          ],
        ),
      ),
    );
  }
}
