// lib/screens/admin/dedication_dialog.dart
//
// The admin form for "Sadaka Jariya in memory of ...". Sets, changes or removes
// the dedication shown on a cooler's card. It calls the server itself, then
// tells the screen what happened through `notify` and `onChanged`.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../services/api_service.dart';

Future<void> showDedicationDialog(
  BuildContext context, {
  required WaterCooler cooler,
  required ApiService api,
  required void Function(String message, {bool isError}) notify,
  required VoidCallback onChanged,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _DedicationDialog(
      cooler: cooler,
      api: api,
      notify: notify,
      onChanged: onChanged,
    ),
  );
}

// A StatefulWidget so the text controllers are disposed with the dialog.
class _DedicationDialog extends StatefulWidget {
  final WaterCooler cooler;
  final ApiService api;
  final void Function(String message, {bool isError}) notify;
  final VoidCallback onChanged;

  const _DedicationDialog({
    required this.cooler,
    required this.api,
    required this.notify,
    required this.onChanged,
  });

  @override
  State<_DedicationDialog> createState() => _DedicationDialogState();
}

class _DedicationDialogState extends State<_DedicationDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _messageCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  bool get _hasDedication => widget.cooler.dedicatedTo != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cooler.dedicatedTo ?? '');
    _messageCtrl = TextEditingController(text: widget.cooler.dedicationMessage ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
      widget.notify(doneMessage);
      widget.onChanged();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      widget.notify(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _save() {
    if (!_formKey.currentState!.validate()) return Future.value();
    return _run(
      () => widget.api.setDedication(
        coolerId: widget.cooler.id,
        dedicatedTo: _nameCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      ),
      '✓ Dedication saved.',
    );
  }

  Future<void> _remove() => _run(
        () => widget.api.clearDedication(widget.cooler.id),
        'Dedication removed.',
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('In memory of', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.cooler.name,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                    labelText: 'In memory of (name)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                enabled: !_loading,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageCtrl,
                maxLength: 280,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Short message (optional)', border: OutlineInputBorder()),
                enabled: !_loading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_hasDedication)
          TextButton(
            onPressed: _loading ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
