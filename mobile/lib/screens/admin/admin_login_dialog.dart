// lib/screens/admin/admin_login_dialog.dart
//
// The admin sign-in pop-up. Returns true when the admin logged in.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/api_service.dart';

Future<bool> showAdminLoginDialog(BuildContext context, ApiService api) async {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Verify Administrative Account'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder()),
              enabled: !loading,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
              enabled: !loading,
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    final user = usernameController.text.trim();
                    final pass = passwordController;
                    if (user.isEmpty || pass.text.isEmpty) {
                      setDialog(() => error = 'Credentials required.');
                      return;
                    }
                    setDialog(() {
                      loading = true;
                      error = null;
                    });
                    try {
                      await api.adminLogin(username: user, password: pass.text);
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (_) {
                      setDialog(() {
                        loading = false;
                        error = 'Invalid administrative credentials.';
                      });
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Authenticate'),
          ),
        ],
      ),
    ),
  );

  usernameController.dispose();
  passwordController.dispose();
  return success == true;
}
