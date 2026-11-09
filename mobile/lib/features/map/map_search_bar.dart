import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../cooler/cooler_repository.dart';
import 'user_location_controller.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({
    super.key,
    required this.onSelected,
    required this.onProfile,
  });

  final void Function(Cooler cooler) onSelected;
  final VoidCallback onProfile;

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<Cooler>? _results;
  bool _searching = false;
  String? _error;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _results = null;
        _error = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text.trim()));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final near = ref.read(userLocationProvider).position;
      final results = await ref.read(coolerRepositoryProvider).search(q, near: near);
      if (!mounted || seq != _seq) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() => _error = errorText(context.l10n, e));
    } finally {
      if (mounted && seq == _seq) setState(() => _searching = false);
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Row(children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 14, end: 8),
            child: Icon(Icons.water_drop_rounded, color: AppColors.primary),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (t) => t.trim().isEmpty ? null : _search(t.trim()),
              decoration: InputDecoration(
                hintText: l.searchHint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_controller.text.isNotEmpty)
            IconButton(onPressed: _clear, icon: const Icon(Icons.close), tooltip: l.searchClear),
          IconButton(
            onPressed: widget.onProfile,
            tooltip: loggedIn ? l.profile : l.authLogin,
            icon: Icon(
              loggedIn ? Icons.account_circle : Icons.account_circle_outlined,
              color: loggedIn ? AppColors.primary : AppColors.muted,
            ),
          ),
        ]),
      ),
      if (_results != null || _error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _error != null
                  ? ListTile(leading: const Icon(Icons.cloud_off), title: Text(_error!))
                  : _results!.isEmpty
                      ? ListTile(title: Text(l.searchNoResults))
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _results!.length,
                          itemBuilder: (_, i) {
                            final c = _results![i];
                            return ListTile(
                              leading: Icon(c.status.icon, color: c.status.color),
                              title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(c.status.label(l)),
                              onTap: () {
                                _clear();
                                widget.onSelected(c);
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
    ]);
  }
}
