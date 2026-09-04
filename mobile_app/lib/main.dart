import 'package:flutter/material.dart';

import 'screens/create_prescription_page.dart';
import 'screens/diseases_page.dart';
import 'screens/medicines_page.dart';
import 'screens/patients_page.dart';
import 'screens/settings_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skin Care Centre',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E79),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        useMaterial3: true,
      ),
      home: const ClinicShell(),
    );
  }
}

class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key});

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    _DashboardPage(),
    PatientsPage(),
    MedicinesPage(),
    DiseasesPage(),
    CreatePrescriptionPage(),
    SettingsPage(),
  ];

  static const _items = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Patients'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.medication_outlined),
      selectedIcon: Icon(Icons.medication),
      label: Text('Medicines'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.biotech_outlined),
      selectedIcon: Icon(Icons.biotech),
      label: Text('Diseases'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: Text('Prescription'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isExtended = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExtended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF1F4E79),
                    child: Icon(Icons.health_and_safety, color: Colors.white),
                  ),
                  if (isExtended) ...[
                    const SizedBox(height: 8),
                    const Text('Skin Care Centre', textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            destinations: _items,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Welcome back, Doctor',
      subtitle: 'Manage your clinic efficiently',
      child: GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
        children: const [
          _MetricCard(
            label: 'Total Patients',
            value: '1,809',
            icon: Icons.people,
          ),
          _MetricCard(
            label: 'Total Medicines',
            value: '112',
            icon: Icons.medication,
          ),
          _MetricCard(
            label: 'Total Prescriptions',
            value: '2,351',
            icon: Icons.description,
          ),
          _MetricCard(
            label: "Today's Prescriptions",
            value: '0',
            icon: Icons.today,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
