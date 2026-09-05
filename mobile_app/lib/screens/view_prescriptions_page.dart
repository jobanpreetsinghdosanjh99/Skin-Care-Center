import 'package:flutter/material.dart';

import '../models/prescription.dart';
import '../services/prescriptions_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

/// Read-only prescriptions list shown to restricted accounts (the
/// 'manager' role) instead of [CreatePrescriptionPage] — they can browse
/// prescriptions and see their amounts, but cannot create, repeat, print
/// or download them, so those actions are hidden here entirely rather
/// than shown and then failing.
class ViewPrescriptionsPage extends StatefulWidget {
  const ViewPrescriptionsPage({super.key});

  @override
  State<ViewPrescriptionsPage> createState() => _ViewPrescriptionsPageState();
}

class _ViewPrescriptionsPageState extends State<ViewPrescriptionsPage> {
  final _api = PrescriptionsApi();
  late Future<List<Prescription>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _refresh() {
    setState(() => _future = _api.list());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Prescriptions',
              subtitle: 'View patient prescriptions and their amounts',
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<List<Prescription>>(
                future: _future,
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
                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: prescriptions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prescription = prescriptions[index];
                          return ExpansionTile(
                            leading: InitialsAvatar(
                              text: prescription.patientName,
                              icon: Icons.description_outlined,
                            ),
                            title: Text(
                              '${prescription.patientName.toTitleCase} '
                              '• ₹${prescription.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Patient #${prescription.patientNumber} • '
                              '${prescription.items.length} item(s)'
                              '${prescription.duration != null ? ' • ${prescription.duration}' : ''}\n'
                              '${prescription.createdAt.day.toString().padLeft(2, '0')}/'
                              '${prescription.createdAt.month.toString().padLeft(2, '0')}/'
                              '${prescription.createdAt.year} • '
                              '${prescription.status.toTitleCase}'
                              '${prescription.diseases.isNotEmpty ? ' • ${prescription.diseases.map((d) => d.shortName.toTitleCase).join(', ')}' : ''}'
                              '${(prescription.diagnosisNotes ?? '').isNotEmpty ? ' • ${prescription.diagnosisNotes}' : ''}',
                            ),
                            children: [
                              if (prescription.diseases.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Diagnosis: ${prescription.diseases.map((d) => d.shortName.toTitleCase).join(', ')}'
                                      '${(prescription.diagnosisNotes ?? '').isNotEmpty ? ' — ${prescription.diagnosisNotes}' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              if ((prescription.generalInstructions ?? '')
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Instructions:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(prescription.generalInstructions!),
                                    ],
                                  ),
                                ),
                              if ((prescription.footerNote ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    0,
                                  ),
                                  child: Text(
                                    prescription.footerNote!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final item in prescription.items)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.medication,
                                    size: 18,
                                    color: AppTheme.secondary,
                                  ),
                                  title: Text(item.medicineName.toTitleCase),
                                  subtitle: Text(
                                    '${item.dosage} • Qty: ${item.quantity}'
                                    '${item.instructions != null ? ' • ${item.instructions}' : ''}'
                                    ' • ₹${item.unitPrice.toStringAsFixed(2)} × ${item.quantity} = '
                                    '₹${item.totalPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                            ],
                          );
                        },
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
