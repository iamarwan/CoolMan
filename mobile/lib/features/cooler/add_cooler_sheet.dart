// Step 2 of adding a cooler: details and photos (step 1 is placing the pin).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../core/location_service.dart';
import '../../core/session.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../map/map_pins_controller.dart';
import '../profile/profile_repository.dart';
import 'cooler_repository.dart';
import 'photo_picker.dart';

const _maxPhotos = 3;

/// Returns the created cooler, or null if cancelled. [at] is where the user
/// was standing when they confirmed the pin (sent for the "be there" rule).
Future<Cooler?> showAddCoolerSheet(BuildContext context, LatLng point, {Fix? at}) {
  return showModalBottomSheet<Cooler>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddCoolerSheet(point: point, at: at),
  );
}

/// The four answers to "are there cups?".
enum _Cups { disposable, shared, none, unknown }

class _AddCoolerSheet extends ConsumerStatefulWidget {
  const _AddCoolerSheet({required this.point, this.at});

  final LatLng point;
  final Fix? at;

  @override
  ConsumerState<_AddCoolerSheet> createState() => _AddCoolerSheetState();
}

class _AddCoolerSheetState extends ConsumerState<_AddCoolerSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  CoolerStatus _status = CoolerStatus.working;
  _Cups _cups = _Cups.unknown;
  final List<PickedPhoto> _photos = [];
  bool _busy = false;
  String? _progress;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final p = await pickPhoto(context);
    if (p != null && mounted) setState(() => _photos.add(p));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = context.l10n.saving;
    });
    final repo = ref.read(coolerRepositoryProvider);
    try {
      final cooler = await repo.create(
        name: _name.text.trim(),
        point: widget.point,
        status: _status,
        hasCups: switch (_cups) {
          _Cups.disposable || _Cups.shared => true,
          _Cups.none => false,
          _Cups.unknown => null,
        },
        cupsType: switch (_cups) {
          _Cups.disposable => CupsType.disposable,
          _Cups.shared => CupsType.communal,
          _ => null,
        },
        at: widget.at,
      );

      var failed = 0;
      for (var i = 0; i < _photos.length; i++) {
        if (mounted) setState(() => _progress = context.l10n.uploadingPhoto(i + 1, _photos.length));
        try {
          await repo.uploadPhoto(cooler.id, _photos[i].path, _photos[i].category, at: widget.at);
        } catch (_) {
          failed++;
        }
      }

      // Show it on the map right away; a cooler in review is visible to its author only.
      ref.read(mapPinsProvider.notifier).upsert(cooler.toPin());
      ref.read(sessionProvider.notifier).refreshProfile();
      refreshMyData(ref);
      if (!mounted) return;
      if (failed > 0) showSnack(context, context.l10n.photosFailed(failed), error: true);
      Navigator.of(context).pop(cooler);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(context.l10n, e);
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SheetHandle(),
            Text(l.stepOf(2, 2).toUpperCase(),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.primaryDark)),
            Text(l.addTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(children: [
                const Icon(Icons.place, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.locationConfirmed,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                ),
                Text(
                  '${widget.point.latitude.toStringAsFixed(4)}, ${widget.point.longitude.toStringAsFixed(4)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            _Label(l.addNameLabel),
            TextFormField(
              controller: _name,
              maxLength: 255,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: l.addNameHint, counterText: ''),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return l.addNameRequired;
                if (RegExp(r'[<>]').hasMatch(t)) return l.addNameInvalid;
                return null;
              },
            ),
            const SizedBox(height: 18),
            _Label(l.addCupsQuestion),
            for (final (value, icon, title, hint) in [
              (_Cups.disposable, Icons.local_cafe_outlined, l.cupsDisposable, l.cupsDisposableHint),
              (_Cups.shared, Icons.groups_2_outlined, l.cupsShared, l.cupsSharedHint),
              (_Cups.none, Icons.no_drinks_outlined, l.cupsNone, l.cupsNoneHint),
              (_Cups.unknown, Icons.help_outline, l.notSure, l.cupsUnknownHint),
            ])
              _ChoiceCard(
                icon: icon,
                title: title,
                subtitle: hint,
                selected: _cups == value,
                onTap: () => setState(() => _cups = value),
              ),
            const SizedBox(height: 12),
            _Label(l.addWorkingNow),
            Row(children: [
              for (final s in CoolerStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _StatusOption(
                      status: s,
                      selected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            _Label(l.addPhotos),
            SizedBox(
              height: 96,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < _photos.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: Image.file(File(_photos[i].path),
                            width: 96, height: 96, fit: BoxFit.cover, cacheWidth: 220),
                      ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.broken,
                            child: Icon(Icons.delete_outline, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                if (_photos.length < _maxPhotos)
                  InkWell(
                    onTap: _busy ? null : _addPhoto,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDark),
                        const SizedBox(height: 6),
                        Text(l.addPhoto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(child: Text(l.reviewNote, style: const TextStyle(height: 1.45))),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.broken, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(_busy ? (_progress ?? l.saving) : l.submitCooler),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? AppColors.surfaceTint : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.5 : 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                IconBadge(
                  icon,
                  size: 38,
                  color: selected ? Colors.white : AppColors.ink,
                  background: selected ? AppColors.primary : AppColors.surfaceLow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.line,
                ),
              ]),
            ),
          ),
        ),
      );
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({required this.status, required this.selected, required this.onTap});

  final CoolerStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? status.background : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: selected ? status.color : AppColors.line, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(children: [
              Icon(status.icon, color: status.color),
              const SizedBox(height: 4),
              Text(
                status.label(context.l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
      );
}
