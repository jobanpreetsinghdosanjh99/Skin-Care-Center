import 'package:flutter/foundation.dart';

/// Tiny app-wide signal that increments whenever the active clinic
/// changes (e.g. the user switches clinics from Settings).
///
/// Every page keeps its own `Future` state loaded once in `initState`
/// and cached inside an `IndexedStack`, so simply switching the active
/// clinic on the backend does nothing to already-built pages — Patients,
/// Medicines, Diseases, etc. would keep showing stale data from the
/// previous clinic until manually refreshed. Listening to this notifier
/// lets [MainApp] force those pages to rebuild from scratch immediately.
class ClinicScope {
  ClinicScope._();

  static final ValueNotifier<int> epoch = ValueNotifier<int>(0);

  static void notifyClinicChanged() {
    epoch.value++;
  }
}
