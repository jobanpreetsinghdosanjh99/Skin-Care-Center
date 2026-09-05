import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/clinic.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../screens/create_prescription_page.dart';
import '../services/clinics_api.dart';
import '../services/patients_api.dart';
import '../utils/prescription_pdf.dart';

/// Row of explicit prescription actions — Print, Download, and (optionally)
/// Repeat — matching the old third-party app's prescription toolbar
/// instead of a single ambiguous "print" icon.
///
/// [showRepeat] should only be true when browsing a patient's existing
/// prescription history (e.g. from Patient Detail or the prescriptions
/// list), where re-issuing a past prescription makes sense. It should be
/// false right after creating a brand-new prescription, since "repeat"
/// on something just created is meaningless.
/// [showPrint] / [showDownload] let restricted roles (the 'manager' role)
/// review a prescription — including its amount — without being able to
/// print or export it.
class PrescriptionActions extends StatelessWidget {
  const PrescriptionActions({
    super.key,
    required this.prescription,
    this.dense = false,
    this.showRepeat = true,
    this.showPrint = true,
    this.showDownload = true,
  });

  final Prescription prescription;
  final bool dense;
  final bool showRepeat;
  final bool showPrint;
  final bool showDownload;

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
    // Nothing to show at all (e.g. a manager, who may view amounts but not
    // print/download/repeat) — collapse instead of rendering an empty row.
    if (!showPrint && !showDownload && !showRepeat) {
      return const SizedBox.shrink();
    }
    if (dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPrint)
            IconButton(
              onPressed: () => _print(context),
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'Print',
            ),
          if (showDownload)
            IconButton(
              onPressed: () => _download(context),
              icon: const Icon(Icons.download_outlined, size: 20),
              tooltip: 'Download',
            ),
          if (showRepeat)
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
        if (showPrint)
          OutlinedButton.icon(
            onPressed: () => _print(context),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print'),
          ),
        if (showDownload)
          OutlinedButton.icon(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download'),
          ),
        if (showRepeat)
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
