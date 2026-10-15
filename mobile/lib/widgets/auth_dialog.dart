// lib/widgets/auth_dialog.dart
//
// The login / register pop-up. Show it with:
//   final loggedIn = await showDialog<bool>(context: context, builder: (_) => const AuthDialog());
// It closes with `true` when the person logged in or registered.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/api_service.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});
  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _loginKey = GlobalKey<FormState>();
  final _regKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isLogin = _tabs.index == 0;
    final key = isLogin ? _loginKey : _regKey;
    if (!key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (isLogin) {
        await _api.userLogin(
            username: _loginUserCtrl.text.trim(),
            password: _loginPassCtrl.text);
      } else {
        await _api.register(
            username: _regUserCtrl.text.trim(),
            password: _regPassCtrl.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Access Sabil Network',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabs,
                children: [
                  Form(
                    key: _loginKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _loginUserCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _loginPassCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          enabled: !_loading,
                        ),
                      ],
                    ),
                  ),
                  Form(
                    key: _regKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _regUserCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length < 3) return 'Min 3 chars';
                            if (!RegExp(r"^[a-zA-Z0-9_]+$")
                                .hasMatch(v.trim())) {
                              return 'Alpha-numerics only';
                            }
                            return null;
                          },
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _regPassCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Password (8+ chars)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 8) return 'Min 8 characters';
                            return null;
                          },
                          enabled: !_loading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_tabs.index == 0 ? 'Login' : 'Register'),
        ),
      ],
    );
  }
}
