// lib/screens/admin/create_sponsor_dialog.dart
//
// The "Create New Sponsor" form. It calls the server itself, then tells the
// screen what happened through `notify` (message) and `onCreated` (refresh).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/api_service.dart';

Future<void> showCreateSponsorDialog(
  BuildContext context, {
  required ApiService api,
  required void Function(String message, {bool isError}) notify,
  required VoidCallback onCreated,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _CreateSponsorDialog(api: api, notify: notify, onCreated: onCreated),
  );
}

// A StatefulWidget so the text controllers are disposed together with the
// dialog (after its close animation), not while it is still on screen.
class _CreateSponsorDialog extends StatefulWidget {
  final ApiService api;
  final void Function(String message, {bool isError}) notify;
  final VoidCallback onCreated;

  const _CreateSponsorDialog({
    required this.api,
    required this.notify,
    required this.onCreated,
  });

  @override
  State<_CreateSponsorDialog> createState() => _CreateSponsorDialogState();
}

class _CreateSponsorDialogState extends State<_CreateSponsorDialog> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Business';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final contact = _contactCtrl.text.trim();
      await widget.api.createSponsor(
        name: _nameCtrl.text.trim(),
        sponsorType: _selectedType,
        contact: contact.isEmpty ? null : contact,
      );
      if (mounted) Navigator.of(context).pop();
      widget.notify('✓ Sponsor successfully created.');
      widget.onCreated();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      widget.notify('Failed to create sponsor: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Sponsor', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sponsor Entity Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: !_loading,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                  labelText: 'Sponsor Category', border: OutlineInputBorder()),
              items: ['Business', 'Mosque', 'Individual', 'NGO']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                  labelText: 'Contact Information', border: OutlineInputBorder()),
              enabled: !_loading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}
