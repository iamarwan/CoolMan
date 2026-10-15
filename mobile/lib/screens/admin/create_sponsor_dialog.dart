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
  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  String selectedType = 'Business';
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Create New Sponsor',
            style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sponsor Entity Name', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                enabled: !loading,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                    labelText: 'Sponsor Category', border: OutlineInputBorder()),
                items: ['Business', 'Mosque', 'Individual', 'NGO']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setDialog(() => selectedType = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: contactCtrl,
                decoration: const InputDecoration(
                    labelText: 'Contact Information',
                    border: OutlineInputBorder()),
                enabled: !loading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialog(() => loading = true);
                    try {
                      await api.createSponsor(
                        name: nameCtrl.text.trim(),
                        sponsorType: selectedType,
                        contact: contactCtrl.text.trim().isEmpty
                            ? null
                            : contactCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      notify('✓ Sponsor successfully created.');
                      onCreated();
                    } catch (e) {
                      setDialog(() => loading = false);
                      notify('Failed to create sponsor: $e', isError: true);
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
  nameCtrl.dispose();
  contactCtrl.dispose();
}
