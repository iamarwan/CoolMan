// Add-cooler details form (shown after the user places the pin).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../map/map_pins_controller.dart';
import 'cooler_repository.dart';
import 'photo_picker.dart';

const _maxPhotos = 3;

/// Returns the created cooler, or null if cancelled.
Future<Cooler?> showAddCoolerSheet(BuildContext context, LatLng point) {
  return showModalBottomSheet<Cooler>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddCoolerSheet(point: point),
  );
}

class _AddCoolerSheet extends ConsumerStatefulWidget {
  const _AddCoolerSheet({required this.point});

  final LatLng point;

  @override
  ConsumerState<_AddCoolerSheet> createState() => _AddCoolerSheetState();
}

class _AddCoolerSheetState extends ConsumerState<_AddCoolerSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  CoolerStatus _status = CoolerStatus.working;
  bool? _hasCups;
  CupsType? _cupsType;
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
        hasCups: _hasCups,
        cupsType: _cupsType,
      );

      var failed = 0;
      for (var i = 0; i < _photos.length; i++) {
        if (mounted) setState(() => _progress = context.l10n.uploadingPhoto(i + 1, _photos.length));
        try {
          await repo.uploadPhoto(cooler.id, _photos[i].path, _photos[i].category);
        } catch (_) {
          failed++;
        }
      }

      if (cooler.isApproved) ref.read(mapPinsProvider.notifier).upsert(cooler.toPin());
      ref.read(sessionProvider.notifier).refreshProfile();
      if (!mounted) return;
      if (failed > 0) {
        showSnack(context, context.l10n.photosFailed(failed), error: true);
      }
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const SheetHandle(),
            Text(l.addTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 255,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.addNameLabel,
                hintText: l.addNameHint,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return l.addNameRequired;
                if (RegExp(r'[<>]').hasMatch(t)) return l.addNameInvalid;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Label(l.addWorkingNow),
            SegmentedButton<CoolerStatus>(
              segments: [
                for (final s in CoolerStatus.values)
                  ButtonSegment(value: s, icon: Icon(s.icon, color: s.color), label: Text(s.label(l))),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
            const SizedBox(height: 16),
            _Label(l.addCupsQuestion),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: Text(l.yes),
                selected: _hasCups == true,
                onSelected: (_) => setState(() => _hasCups = true),
              ),
              ChoiceChip(
                label: Text(l.no),
                selected: _hasCups == false,
                onSelected: (_) => setState(() {
                  _hasCups = false;
                  _cupsType = null;
                }),
              ),
              ChoiceChip(
                label: Text(l.notSure),
                selected: _hasCups == null,
                onSelected: (_) => setState(() {
                  _hasCups = null;
                  _cupsType = null;
                }),
              ),
            ]),
            if (_hasCups == true) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: Text(l.cupsShared),
                  selected: _cupsType == CupsType.communal,
                  onSelected: (_) => setState(() => _cupsType = CupsType.communal),
                ),
                ChoiceChip(
                  label: Text(l.cupsDisposable),
                  selected: _cupsType == CupsType.disposable,
                  onSelected: (_) => setState(() => _cupsType = CupsType.disposable),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            _Label(l.addPhotos),
            SizedBox(
              height: 84,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < _photos.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_photos[i].path),
                            width: 84, height: 84, fit: BoxFit.cover, cacheWidth: 200),
                      ),
                      PositionedDirectional(
                        top: 2,
                        end: 2,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                if (_photos.length < _maxPhotos)
                  InkWell(
                    onTap: _busy ? null : _addPhoto,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 84,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.muted),
                    ),
                  ),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.broken)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(_busy ? (_progress ?? l.saving) : l.submit),
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
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
