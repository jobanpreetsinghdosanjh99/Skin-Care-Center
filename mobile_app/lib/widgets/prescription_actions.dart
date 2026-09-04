import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/clinic.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../screens/create_prescription_page.dart';
import '../services/clinics_api.dart';
import '../services/patients_api.dart';
import '../utils/prescription_pdf.dart';

/// Row of three explicit actions for a prescription — Print, Download,
/// and Repeat — matching the old third-party app's prescription toolbar
/// instead of a single ambiguous "print" icon.
class PrescriptionActions extends StatelessWidget {
  const PrescriptionActions({
    super.key,
    required this.prescription,
    this.dense = false,
  });

  final Prescription prescription;
  final bool dense;

  static final _clinicsApi = ClinicsApi();
  static final _patientsApi = PatientsApi();

  Future<_PrintContext> _loadContext() async {
    final clinic = await _clinicsApi.getActive();
    final patient = await _patientsApi.get(prescription.patientId);
    return _PrintContext(clinic, patient);
  }

  Future<void> _print(BuildContext context) async {
    try {
      final ctx = await _loadContext();
      final doc = await PrescriptionPdf.build(
        clinic: ctx.clinic,
        patient: ctx.patient,
        prescription: prescription,
      );
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      if (context.mounted) _showError(context, 'print', e);
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      final ctx = await _loadContext();
      final doc = await PrescriptionPdf.build(
        clinic: ctx.clinic,
        patient: ctx.patient,
        prescription: prescription,
      );
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'prescription_${ctx.patient.fullName.replaceAll(' ', '_')}_'
            '${prescription.createdAt.millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'download', e);
    }
  }

  Future<void> _repeat(BuildContext context) async {
    try {
      final ctx = await _loadContext();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreatePrescriptionPage(
            preselectedPatient: ctx.patient,
            repeatFrom: prescription,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'repeat', e);
    }
  }

  void _showError(BuildContext context, String action, Object e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to $action: $e')));
  }

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _print(context),
            icon: const Icon(Icons.print_outlined, size: 20),
            tooltip: 'Print',
          ),
          IconButton(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () => _repeat(context),
            icon: const Icon(Icons.repeat_rounded, size: 20),
            tooltip: 'Repeat',
          ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _print(context),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Print'),
        ),
        OutlinedButton.icon(
          onPressed: () => _download(context),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Download'),
        ),
        OutlinedButton.icon(
          onPressed: () => _repeat(context),
          icon: const Icon(Icons.repeat_rounded, size: 18),
          label: const Text('Repeat'),
        ),
      ],
    );
  }
}

class _PrintContext {
  const _PrintContext(this.clinic, this.patient);

  final Clinic clinic;
  final Patient patient;
}
