// lib/screens/admin/admin_login_dialog.dart
//
// The admin sign-in pop-up. Returns true when the admin logged in.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/api_service.dart';

Future<bool> showAdminLoginDialog(BuildContext context, ApiService api) async {
  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AdminLoginDialog(api: api),
  );
  return success == true;
}

// A StatefulWidget so the text controllers are disposed together with the
// dialog (after its close animation), not while it is still on screen.
class _AdminLoginDialog extends StatefulWidget {
  final ApiService api;
  const _AdminLoginDialog({required this.api});

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Credentials required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.adminLogin(username: username, password: password);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Invalid administrative credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Administrative Account'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder()),
            enabled: !_loading,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            obscureText: true,
            enabled: !_loading,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Authenticate'),
        ),
      ],
    );
  }
}
