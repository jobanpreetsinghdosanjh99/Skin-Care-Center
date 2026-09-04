import 'package:flutter/material.dart';

import '../models/footer_note.dart';
import '../services/clinic_scope.dart';
import '../services/clinics_api.dart';
import '../services/settings_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = SettingsApi();
  final _clinicsApi = ClinicsApi();
  late Future<List<FooterNote>> _footerNotesFuture;
  late Future<List<Map<String, dynamic>>> _clinicsFuture;

  @override
  void initState() {
    super.initState();
    _footerNotesFuture = _api.listFooterNotes();
    _clinicsFuture = _clinicsApi.list();
    ClinicScope.epoch.addListener(_onClinicChanged);
  }

  @override
  void dispose() {
    ClinicScope.epoch.removeListener(_onClinicChanged);
    super.dispose();
  }

  void _onClinicChanged() {
    _refreshFooterNotes();
    _refreshClinics();
  }

  void _refreshFooterNotes() {
    setState(() {
      _footerNotesFuture = _api.listFooterNotes();
    });
  }

  void _refreshClinics() {
    setState(() {
      _clinicsFuture = _clinicsApi.list();
    });
  }

  Future<void> _openChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? error;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              await _api.changePassword(
                currentPassword: currentController.text,
                newPassword: newController.text,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully'),
                  ),
                );
              }
            } catch (e) {
              setDialogState(() => error = e.toString());
            } finally {
              setDialogState(() => submitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            content: SizedBox(
              width: 380,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: newController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Must be at least 8 characters'
                          : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ErrorBanner(message: error!),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreateClinicDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? error;
    bool submitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              await _clinicsApi.create(
                name: nameController.text.trim().toTitleCase,
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim().toSentenceCase,
              );
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              setDialogState(() => error = e.toString());
            } finally {
              setDialogState(() => submitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Create New Clinic'),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic Name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ErrorBanner(message: error!),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Clinic'),
              ),
            ],
          );
        },
      ),
    );
    if (created == true) _refreshClinics();
  }

  Future<void> _openClinicListDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clinic List'),
        content: SizedBox(
          width: 420,
          height: 320,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _clinicsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoader();
              }
              final clinics = snapshot.data ?? [];
              if (clinics.isEmpty) {
                return const EmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'No clinics found',
                );
              }
              return ListView.separated(
                itemCount: clinics.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final clinic = clinics[index];
                  final isActive = clinic['is_active'] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.local_hospital_rounded,
                      color: isActive ? AppTheme.primary : Colors.grey,
                    ),
                    title: Text(
                      (clinic['name'] as String).toTitleCase,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text((clinic['phone'] as String?) ?? ''),
                    trailing: isActive
                        ? const StatusPill(
                            label: 'Active',
                            color: AppTheme.success,
                          )
                        : TextButton(
                            onPressed: () async {
                              await _clinicsApi.activate(
                                clinic['id'] as String,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                              _refreshClinics();
                              ClinicScope.notifyClinicChanged();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Clinic switched. Refreshing data…',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Switch'),
                          ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFooterNoteDialog({FooterNote? existing}) async {
    final controller = TextEditingController(text: existing?.note ?? '');
    final isEditing = existing != null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Footer Note' : 'Add Footer Note'),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Note'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              if (isEditing) {
                await _api.updateFooterNote(
                  existing.id,
                  note: controller.text.trim(),
                  sortOrder: existing.sortOrder,
                  isActive: existing.isActive,
                );
              } else {
                final notes = await _footerNotesFuture;
                final nextOrder = notes.isEmpty
                    ? 0
                    : notes
                              .map((n) => n.sortOrder)
                              .reduce((a, b) => a > b ? a : b) +
                          1;
                await _api.addFooterNote(
                  controller.text.trim(),
                  sortOrder: nextOrder,
                );
              }
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) _refreshFooterNotes();
  }

  Future<void> _confirmDeleteFooterNote(FooterNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Footer Note'),
        content: const Text('Are you sure you want to delete this note?'),
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
    if (confirmed != true) return;
    await _api.deleteFooterNote(note.id);
    _refreshFooterNotes();
  }

  Future<void> _toggleFooterNoteActive(FooterNote note) async {
    await _api.updateFooterNote(
      note.id,
      note: note.note,
      sortOrder: note.sortOrder,
      isActive: !note.isActive,
    );
    _refreshFooterNotes();
  }

  Future<void> _moveFooterNote(
    List<FooterNote> notes,
    int index,
    int delta,
  ) async {
    final targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= notes.length) return;
    final a = notes[index];
    final b = notes[targetIndex];
    await _api.updateFooterNote(
      a.id,
      note: a.note,
      sortOrder: b.sortOrder,
      isActive: a.isActive,
    );
    await _api.updateFooterNote(
      b.id,
      note: b.note,
      sortOrder: a.sortOrder,
      isActive: b.isActive,
    );
    _refreshFooterNotes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Manage your account, clinic, and prescription setup',
            ),
            const SizedBox(height: AppSpacing.lg),
            _SettingsSection(
              icon: Icons.security_rounded,
              iconColor: AppTheme.primary,
              title: 'Account Security',
              description: 'Change your account password for better security.',
              child: OutlinedButton.icon(
                onPressed: _openChangePasswordDialog,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Change Password'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              icon: Icons.local_hospital_rounded,
              iconColor: AppTheme.secondary,
              title: 'Clinic Management',
              description:
                  'Manage your clinic information. You can create a new clinic '
                  'or update existing details.',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: _openCreateClinicDialog,
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('Create New Clinic'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openClinicListDialog,
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('Clinic List'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              icon: Icons.notes_rounded,
              iconColor: const Color(0xFF6D5DD3),
              title: 'Prescription Footer Notes',
              description:
                  'Manage the notes printed at the bottom of every '
                  'prescription. Notes are printed in order, top to bottom; '
                  'inactive notes are hidden from printed prescriptions.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openFooterNoteDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Footer Note'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FutureBuilder<List<FooterNote>>(
                    future: _footerNotesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: AppLoader(),
                        );
                      }
                      final notes = snapshot.data ?? [];
                      if (notes.isEmpty) {
                        return Text(
                          'No footer notes yet.',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: notes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final note = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 16,
                                  color: note.isActive
                                      ? AppTheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note.note,
                                    style: TextStyle(
                                      color: note.isActive ? null : Colors.grey,
                                      decoration: note.isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: index == 0
                                      ? null
                                      : () => _moveFooterNote(notes, index, -1),
                                  icon: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                  ),
                                  tooltip: 'Move up',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: index == notes.length - 1
                                      ? null
                                      : () => _moveFooterNote(notes, index, 1),
                                  icon: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                  ),
                                  tooltip: 'Move down',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _toggleFooterNoteActive(note),
                                  icon: Icon(
                                    note.isActive
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 16,
                                  ),
                                  tooltip: note.isActive
                                      ? 'Hide from print'
                                      : 'Show on print',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _openFooterNoteDialog(existing: note),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  tooltip: 'Edit',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _confirmDeleteFooterNote(note),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppTheme.danger,
                                  ),
                                  tooltip: 'Delete',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
