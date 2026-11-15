// "Build a sabil": one scrolling form in four parts. It sends a request that
// the team follows up from the admin panel (/admin/requests). Nothing is paid
// in the app; the team calls back with a price.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sabil_request.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import 'request_labels.dart';
import 'sabil_request_repository.dart';

/// Opens the form, asking the user to log in first if needed.
Future<void> openSabilRequest(BuildContext context, WidgetRef ref) async {
  if (!await ensureLoggedIn(context, ref) || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SabilRequestScreen()));
}

class SabilRequestScreen extends ConsumerStatefulWidget {
  const SabilRequestScreen({super.key});

  @override
  ConsumerState<SabilRequestScreen> createState() => _SabilRequestScreenState();
}

class _SabilRequestScreenState extends ConsumerState<SabilRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _d = SabilRequestDraft();
  bool _busy = false;
  bool _locating = false;
  // After the first Send, fields re-check as they change so fixed answers turn back to normal.
  bool _tried = false;

  Future<void> _addLocation() async {
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _d.latitude = result.fix?.position.latitude;
      _d.longitude = result.fix?.position.longitude;
    });
    if (result.fix == null) showSnack(context, context.l10n.reqLocationFailed, error: true);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_tried) setState(() => _tried = true);
    if (!_form.currentState!.validate()) {
      showSnack(context, l.reqFixErrors, error: true);
      return;
    }
    _form.currentState!.save();
    setState(() => _busy = true);
    try {
      await ref.read(sabilRequestRepositoryProvider).send(_d);
      ref.invalidate(myRequestsProvider);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const _SentScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, errorText(l, e), error: true);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? context.l10n.reqRequired : null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPin = _d.latitude != null;

    return Scaffold(
      appBar: AppBar(title: Text(l.reqTitle)),
      body: Form(
        key: _form,
        autovalidateMode: _tried ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        // Not a lazy ListView: every part stays built, so answers survive
        // scrolling and the whole form is checked on submit.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                color: AppColors.primaryContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent, color: AppColors.primaryDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.reqIntro, style: const TextStyle(color: AppColors.primaryDark, height: 1.5)),
                    ),
                  ],
                ),
              ),

              // 1. What to build
              _Section(
                number: 1,
                title: l.reqStepWhat,
                children: [
                  for (final code in packageCodes)
                    _PackageTile(
                      info: packageInfo(l, code),
                      selected: _d.package == code,
                      onTap: () => setState(() {
                        _d.package = code;
                        if (code == 'company' && _d.quantity < 2) _d.quantity = 2;
                      }),
                    ),
                  if (_d.package == 'company') ...[
                    _Label(l.reqQuantity),
                    _Stepper(value: _d.quantity, min: 2, max: 50, onChanged: (v) => setState(() => _d.quantity = v)),
                  ],
                  if (_d.package != 'care_only') ...[
                    _Label(l.reqTaps),
                    SegmentedButton<int>(
                      segments: [
                        for (final n in [2, 3, 4]) ButtonSegment(value: n, label: Text(l.reqTapsValue(n))),
                      ],
                      selected: {_d.taps},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _d.taps = s.first),
                    ),
                    _Label(l.reqExtras),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in extraOptions(l))
                          FilterChip(
                            label: Text(o.label),
                            selected: _d.extras.contains(o.code),
                            onSelected: (on) => setState(() => on ? _d.extras.add(o.code) : _d.extras.remove(o.code)),
                          ),
                      ],
                    ),
                  ],
                  _Label(l.reqTiming),
                  _ChoiceField(options: timingOptions(l), initial: _d.timing, onSaved: (v) => _d.timing = v),
                ],
              ),

              // 2. Who it is for
              _Section(
                number: 2,
                title: l.reqStepWho,
                children: [
                  _Label(l.reqPurpose),
                  _ChoiceField(options: purposeOptions(l), initial: _d.purpose, onSaved: (v) => _d.purpose = v),
                  const SizedBox(height: 14),
                  TextFormField(
                    maxLength: 120,
                    decoration: InputDecoration(labelText: l.reqDedication, hintText: l.reqDedicationHint),
                    onSaved: (v) => _d.dedicationName = v ?? '',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    maxLength: 200,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.reqPlaque, hintText: l.reqPlaqueHint),
                    onSaved: (v) => _d.plaqueText = v ?? '',
                  ),
                  MergeSemantics(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.reqShowPublicly, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(l.reqShowPubliclyBody, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(value: _d.showPublicly, onChanged: (v) => setState(() => _d.showPublicly = v)),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. Where
              _Section(
                number: 3,
                title: l.reqStepWhere,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _d.governorate,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.reqGovernorate),
                    items: [
                      for (final code in governorates.keys)
                        DropdownMenuItem(value: code, child: Text(governorateName(context, code))),
                    ],
                    onChanged: (v) => setState(() => _d.governorate = v ?? _d.governorate),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLength: 120,
                    decoration: InputDecoration(labelText: l.reqArea, hintText: l.reqAreaHint),
                    validator: (v) => (v == null || v.trim().length < 2) ? l.reqRequired : null,
                    onSaved: (v) => _d.area = v ?? '',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    maxLength: 300,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.reqAddress),
                    onSaved: (v) => _d.addressNotes = v ?? '',
                  ),
                  if (hasPin)
                    Row(
                      children: [
                        Pill(
                          text: l.reqLocationAdded,
                          icon: Icons.my_location,
                          color: AppColors.working,
                          background: AppColors.workingBg,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _d.latitude = _d.longitude = null),
                          child: Text(l.reqLocationRemove),
                        ),
                      ],
                    )
                  else
                    TintButton(
                      label: l.reqUseLocation,
                      icon: _locating ? Icons.hourglass_top : Icons.my_location,
                      onPressed: _locating ? null : _addLocation,
                    ),
                  _Label(l.reqPlaceType),
                  _ChoiceField(options: placeOptions(l), initial: _d.placeType, onSaved: (v) => _d.placeType = v),
                  _Label(l.reqPermission),
                  _ChoiceField(
                    options: permissionOptions(l),
                    initial: _d.permission,
                    onSaved: (v) => _d.permission = v,
                  ),
                  _Label(l.reqElectricity),
                  _ChoiceField(options: yesNoOptions(l), initial: _d.electricity, onSaved: (v) => _d.electricity = v!),
                  _Label(l.reqWaterLine),
                  _ChoiceField(options: yesNoOptions(l), initial: _d.waterLine, onSaved: (v) => _d.waterLine = v!),
                ],
              ),

              // 4. Contact
              _Section(
                number: 4,
                title: l.reqStepContact,
                children: [
                  TextFormField(
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l.reqName),
                    validator: (v) => (v == null || v.trim().length < 2) ? l.reqRequired : null,
                    onSaved: (v) => _d.contactName = v ?? '',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    decoration: InputDecoration(labelText: l.reqPhone, hintText: '010 1234 5678'),
                    validator: (v) => _required(v) ?? (normalizeEgMobile(v!) == null ? l.reqPhoneInvalid : null),
                    onSaved: (v) => _d.phone = normalizeEgMobile(v ?? '') ?? '',
                  ),
                  _Label(l.reqContactMethod),
                  _ChoiceField(
                    options: contactOptions(l),
                    initial: _d.contactMethod,
                    onSaved: (v) => _d.contactMethod = v!,
                  ),
                  _Label(l.reqBestTime),
                  _ChoiceField(options: bestTimeOptions(l), initial: _d.bestTime, onSaved: (v) => _d.bestTime = v!),
                  const SizedBox(height: 14),
                  TextFormField(
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l.reqNotes),
                    onSaved: (v) => _d.notes = v ?? '',
                  ),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(l.reqPrivacy, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(l.reqSubmit),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.number, required this.title, required this.children});

  final int number;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  '$number',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.info, required this.selected, required this.onTap});

  final ({String title, String body, IconData icon}) info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryContainer.withValues(alpha: 0.5) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.line, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(info.icon, background: selected ? AppColors.surface : AppColors.surfaceLow),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(info.body, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A row of chips where exactly one must be picked.
class _ChoiceField extends FormField<String> {
  _ChoiceField({required List<Option> options, String? initial, super.onSaved})
    : super(
        initialValue: initial,
        validator: (v) => v == null ? '' : null,
        builder: (state) {
          final l = AppLocalizations.of(state.context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options)
                    ChoiceChip(
                      label: Text(o.label),
                      selected: state.value == o.code,
                      onSelected: (_) => state.didChange(o.code),
                    ),
                ],
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.reqRequired,
                    style: TextStyle(color: Theme.of(state.context).colorScheme.error, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Row(
      children: [
        IconButton.filledTonal(onPressed: v > min ? () => onChanged(v - 1) : null, icon: const Icon(Icons.remove)),
        SizedBox(
          width: 56,
          child: Text(
            '$v',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(onPressed: v < max ? () => onChanged(v + 1) : null, icon: const Icon(Icons.add)),
      ],
    );
  }
}

class _SentScreen extends StatelessWidget {
  const _SentScreen();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IconBadge(Icons.check_rounded, size: 72, color: Colors.white, background: AppColors.working),
              const SizedBox(height: 20),
              Text(l.reqSentTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                l.reqSentBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(l.reqDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
