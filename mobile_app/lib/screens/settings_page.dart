import 'package:flutter/material.dart';

import '../services/settings_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = SettingsApi();
  late Future<List<String>> _footerNotesFuture;

  @override
  void initState() {
    super.initState();
    _footerNotesFuture = _api.listFooterNotes();
  }

  void _refreshFooterNotes() {
    setState(() => _footerNotesFuture = _api.listFooterNotes());
  }

  Future<void> _openAddFooterNoteDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Footer Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Note'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _api.addFooterNote(controller.text.trim());
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (added == true) _refreshFooterNotes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.security),
                        SizedBox(width: 8),
                        Text('Account Security', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Change your account password for better security.'),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: () {}, child: const Text('Change Password')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.local_hospital),
                        SizedBox(width: 8),
                        Text('Clinic Management', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your clinic information. You can create a new clinic or update existing details.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(onPressed: () {}, child: const Text('Create New Clinic')),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: () {}, child: const Text('Clinic List')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notes),
                        SizedBox(width: 8),
                        Text(
                          'Prescription Footer Note',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Add, update, or view your prescription footer notes.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _openAddFooterNoteDialog,
                      child: const Text('Add Footer Note'),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<String>>(
                      future: _footerNotesFuture,
                      builder: (context, snapshot) {
                        final notes = snapshot.data ?? [];
                        if (notes.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: notes.map((note) => ListTile(title: Text(note))).toList(),
                        );
                      },
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
