// Lazy login: browsing never needs an account. When a guest tries to
// contribute, this sheet asks them to log in or sign up, then continues.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/session.dart';
import '../../shared/ui.dart';

/// Returns true if the user is (now) logged in.
Future<bool> ensureLoggedIn(BuildContext context, WidgetRef ref) async {
  if (ref.read(sessionProvider).isLoggedIn) return true;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (_) => const _AuthSheet(),
  );
  return ok == true;
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet();

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = ref.read(sessionProvider.notifier);
    try {
      if (_register) {
        await session.register(_username.text.trim(), _password.text);
      } else {
        await session.login(_username.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Text(
              'Log in to contribute',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Browsing is free. An account lets you add coolers, report status and earn trust points.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Log in')),
                ButtonSegment(value: true, label: Text('Create account')),
              ],
              selected: {_register},
              onSelectionChanged: (s) => setState(() {
                _register = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _username,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 3) return 'At least 3 characters';
                if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(t)) {
                  return 'Letters, numbers and _ only';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.broken)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_register ? 'Create account' : 'Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
