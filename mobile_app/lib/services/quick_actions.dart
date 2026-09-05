import 'package:flutter/foundation.dart';

/// Lightweight pub/sub used by the Dashboard's "Quick Actions" buttons to
/// trigger behavior on other tabs (e.g. auto-opening the "Add" dialog)
/// without tightly coupling the dashboard to each page's internal state.
///
/// Each page listens to the relevant notifier in `initState` and opens its
/// own "Add" dialog whenever the value changes, regardless of whether the
/// page happens to be visible yet (the tab switch and the trigger always
/// fire together from [ClinicShell]).
class QuickActions {
  QuickActions._();

  static final ValueNotifier<int> addPatientRequested = ValueNotifier(0);
  static final ValueNotifier<int> addMedicineRequested = ValueNotifier(0);

  static void requestAddPatient() => addPatientRequested.value++;
  static void requestAddMedicine() => addMedicineRequested.value++;
}
