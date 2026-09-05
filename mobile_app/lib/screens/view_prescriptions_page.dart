import 'package:flutter/material.dart';

import '../models/prescription.dart';
import '../services/prescriptions_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';
import '../widgets/prescription_actions.dart';

/// Read-only prescriptions list shown to restricted accounts (the
/// 'manager' role) instead of [CreatePrescriptionPage] — they can browse,
/// print, and download existing prescriptions, but the backend rejects
/// creating/repeating one, so that action is hidden here entirely rather
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
              subtitle: 'View and print patient prescriptions',
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
                          return ListTile(
                            leading: InitialsAvatar(
                              text: prescription.patientName,
                            ),
                            title: Text(
                              prescription.patientName.toTitleCase,
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
                              '${prescription.status.toTitleCase}',
                            ),
                            isThreeLine: true,
                            trailing: PrescriptionActions(
                              prescription: prescription,
                              dense: true,
                              showRepeat: false,
                            ),
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
