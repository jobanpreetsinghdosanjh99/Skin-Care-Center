import 'package:flutter/material.dart';

import 'screens/create_prescription_page.dart';
import 'screens/diseases_page.dart';
import 'screens/login_page.dart';
import 'screens/medicines_page.dart';
import 'screens/patients_page.dart';
import 'screens/settings_page.dart';
import 'services/api_client.dart';
import 'services/auth_api.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

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
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Restores any saved session on startup, then shows [LoginPage] until the
/// user signs in, after which it shows the main [ClinicShell]. Also listens
/// for forced logouts (explicit logout, or a 401 from an expired/invalid
/// token) so the app always falls back to the login screen instead of
/// leaving the user stuck on a broken/empty screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authApi = AuthApi();
  late Future<bool> _restoreFuture;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restoreFuture = _authApi.restoreSession().then((restored) {
      if (mounted) setState(() => _loggedIn = restored);
      return restored;
    });
    AuthSession.loggedOut.addListener(_onLoggedOut);
  }

  @override
  void dispose() {
    AuthSession.loggedOut.removeListener(_onLoggedOut);
    super.dispose();
  }

  void _onLoggedOut() {
    if (mounted) setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return ClinicShell(key: ValueKey(AuthSession.token));
    }
    return FutureBuilder<bool>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: AppLoader()),
          );
        }
        return LoginPage(onLoggedIn: () => setState(() => _loggedIn = true));
      },
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

  final _navigatorKeys = List.generate(6, (_) => GlobalKey<NavigatorState>());

  static const _pages = <Widget>[
    _DashboardPage(),
    PatientsPage(),
    MedicinesPage(),
    DiseasesPage(),
    CreatePrescriptionPage(),
    SettingsPage(),
  ];

  static const _titles = [
    'Dashboard',
    'Patients',
    'Medicines',
    'Diseases',
    'Prescription',
    'Settings',
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    final isExtended = width > 900;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(title: _titles[_selectedIndex]),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              for (var i = 0; i < _pages.length; i++)
                Navigator(
                  key: _navigatorKeys[i],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (context) => _pages[i],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    void onSelect(int index) {
      if (index == _selectedIndex) {
        _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      } else {
        setState(() => _selectedIndex = index);
      }
    }

    // Narrow (phone-sized) windows get a bottom navigation bar instead of a
    // side rail, so page content keeps the full screen width — a side rail
    // was squeezing patient/disease/footer content into too little space.
    if (isMobile) {
      return Scaffold(
        body: SafeArea(child: body),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: onSelect,
          destinations: [
            for (final item in _items)
              NavigationDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: (item.label as Text).data ?? '',
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExtended,
            minExtendedWidth: 220,
            selectedIndex: _selectedIndex,
            onDestinationSelected: onSelect,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                    ),
                  ),
                  if (isExtended) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Skin Care Centre',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: _items,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Slim top bar shown above every page — reinforces the current section
/// and provides a consistent anchor point for future global actions
/// (notifications, profile, etc.).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          const Spacer(),
          const InitialsAvatar(text: 'Doctor', radius: 16),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(title: title, subtitle: subtitle),
            const SizedBox(height: AppSpacing.lg),
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
      title: 'Welcome Back, Doctor',
      subtitle: 'Here is what is happening at your clinic today.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.extent(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              maxCrossAxisExtent: 280,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.4,
              children: const [
                _MetricCard(
                  label: 'Total Patients',
                  value: '1,809',
                  icon: Icons.people_alt_rounded,
                  color: AppTheme.primary,
                ),
                _MetricCard(
                  label: 'Total Medicines',
                  value: '112',
                  icon: Icons.medication_rounded,
                  color: AppTheme.secondary,
                ),
                _MetricCard(
                  label: 'Total Prescriptions',
                  value: '2,351',
                  icon: Icons.description_rounded,
                  color: Color(0xFF6D5DD3),
                ),
                _MetricCard(
                  label: "Today's Prescriptions",
                  value: '0',
                  icon: Icons.today_rounded,
                  color: Color(0xFFDA6C2E),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: const [
                        _QuickAction(
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'Add Patient',
                        ),
                        _QuickAction(
                          icon: Icons.medication_rounded,
                          label: 'Add Medicine',
                        ),
                        _QuickAction(
                          icon: Icons.description_rounded,
                          label: 'New Prescription',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Overview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: const [
                        _SystemStatusCard(
                          icon: Icons.description_rounded,
                          title: 'Prescription System',
                          subtitle: 'Active and operational',
                          statusLabel: 'Online',
                          color: AppTheme.success,
                        ),
                        _SystemStatusCard(
                          icon: Icons.storage_rounded,
                          title: 'Patient Database',
                          subtitle: 'All records secured',
                          statusLabel: 'Secure',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusPill(label: statusLabel, color: color),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
