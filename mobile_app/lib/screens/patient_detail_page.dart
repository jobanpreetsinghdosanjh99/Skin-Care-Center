import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/patient.dart';
import '../models/prescription.dart';
import '../services/clinics_api.dart';
import '../services/patients_api.dart';
import '../services/prescriptions_api.dart';
import '../theme/app_theme.dart';
import '../utils/prescription_pdf.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';
import 'create_prescription_page.dart';

/// Full detail view for a single patient: profile info, edit/delete
/// actions, and the complete list of prescriptions issued to them.
class PatientDetailPage extends StatefulWidget {
  const PatientDetailPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _patientsApi = PatientsApi();
  final _prescriptionsApi = PrescriptionsApi();
  final _clinicsApi = ClinicsApi();

  late Future<Patient> _patientFuture;
  late Future<List<Prescription>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _patientFuture = _patientsApi.get(widget.patientId);
    _prescriptionsFuture = _prescriptionsApi.list(patientId: widget.patientId);
  }

  Future<void> _refresh() async {
    setState(_load);
  }

  Future<void> _openEditPatientDialog(Patient patient) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _PatientEditDialog(patient: patient),
    );
    if (updated == true) _refresh();
  }

  Future<void> _confirmDeletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete "${patient.fullName.toTitleCase}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _patientsApi.delete(patient.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _openCreatePrescription(Patient patient) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePrescriptionPage(preselectedPatient: patient),
      ),
    );
    _refresh();
  }

  Future<void> _printPrescription(Prescription prescription) async {
    try {
      final clinic = await _clinicsApi.getActive();
      final patient = await _patientsApi.get(prescription.patientId);
      final doc = await PrescriptionPdf.build(
        clinic: clinic,
        patient: patient,
        prescription: prescription,
      );
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FutureBuilder<Patient>(
          future: _patientFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoader();
            }
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load patient',
                message: '${snapshot.error}',
              );
            }
            final patient = snapshot.data;
            if (patient == null) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Patient not found',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: PageHeader(
                        title: patient.fullName.toTitleCase,
                        subtitle: 'Patient #${patient.patientNumber}',
                        action: Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openEditPatientDialog(patient),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDeletePatient(patient),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.danger,
                                side: const BorderSide(color: AppTheme.danger),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                            ),
                            FilledButton.icon(
                              onPressed: () => _openCreatePrescription(patient),
                              icon: const Icon(
                                Icons.receipt_long_rounded,
                                size: 18,
                              ),
                              label: const Text('New Prescription'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.md,
                      children: [
                        _InfoTile(
                          icon: Icons.cake_outlined,
                          label: 'Age',
                          value: patient.ageYears != null
                              ? '${patient.ageYears} yrs'
                              : '-',
                        ),
                        _InfoTile(
                          icon: Icons.wc_rounded,
                          label: 'Gender',
                          value: patient.gender.toTitleCase,
                        ),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: patient.phone,
                        ),
                        _InfoTile(
                          icon: Icons.home_outlined,
                          label: 'Address',
                          value: (patient.address ?? '').isNotEmpty
                              ? patient.address!.toSentenceCase
                              : '-',
                        ),
                        _InfoTile(
                          icon: Icons.event_outlined,
                          label: 'Registered',
                          value:
                              '${patient.createdAt.day.toString().padLeft(2, '0')}/'
                              '${patient.createdAt.month.toString().padLeft(2, '0')}/'
                              '${patient.createdAt.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Prescription History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: FutureBuilder<List<Prescription>>(
                    future: _prescriptionsFuture,
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
                          message:
                              'Prescriptions issued to this patient will '
                              'appear here.',
                        );
                      }
                      return Card(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: prescriptions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final prescription = prescriptions[index];
                            return ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.description, size: 18),
                              ),
                              title: Text(
                                '${prescription.items.length} item(s)'
                                '${prescription.duration != null ? ' • ${prescription.duration}' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${prescription.createdAt.day.toString().padLeft(2, '0')}/'
                                '${prescription.createdAt.month.toString().padLeft(2, '0')}/'
                                '${prescription.createdAt.year} • '
                                '${prescription.status.toTitleCase}'
                                '${(prescription.diagnosisNotes ?? '').isNotEmpty ? ' • ${prescription.diagnosisNotes}' : ''}',
                              ),
                              trailing: IconButton(
                                onPressed: () =>
                                    _printPrescription(prescription),
                                icon: const Icon(
                                  Icons.print_outlined,
                                  size: 20,
                                ),
                                tooltip: 'Print',
                              ),
                              children: prescription.items
                                  .map(
                                    (item) => ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.medication,
                                        size: 18,
                                        color: AppTheme.secondary,
                                      ),
                                      title: Text(
                                        item.medicineName.toTitleCase,
                                      ),
                                      subtitle: Text(
                                        '${item.dosage} • Qty: ${item.quantity}'
                                        '${item.instructions != null ? ' • ${item.instructions}' : ''}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone edit dialog used by the detail page (kept independent from
/// the list page's private dialog so this file has no cross-file
/// dependency on `patients_page.dart`'s private widgets).
class _PatientEditDialog extends StatefulWidget {
  const _PatientEditDialog({required this.patient});

  final Patient patient;

  @override
  State<_PatientEditDialog> createState() => _PatientEditDialogState();
}

class _PatientEditDialogState extends State<_PatientEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _api = PatientsApi();
  late final _nameController = TextEditingController(
    text: widget.patient.fullName,
  );
  late final _phoneController = TextEditingController(
    text: widget.patient.phone,
  );
  late final _ageController = TextEditingController(
    text: widget.patient.ageYears?.toString() ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.patient.address ?? '',
  );
  late String _gender = widget.patient.gender;
  bool _saving = false;
  String? _error;

  static const _genders = ['male', 'female', 'other', 'prefer_not_to_say'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.update(
        widget.patient.id,
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
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Patient'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genders
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.toTitleCase),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? _gender),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
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
