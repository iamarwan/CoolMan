// First run: two short pages on what the app does, then the location
// permission request with a plain explanation (as in the Nwasy design).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale.dart';
import '../../core/providers.dart';
import '../../shared/language_picker.dart';
import '../../shared/ui.dart';
import '../home/home_shell.dart';
import '../map/user_location_controller.dart';

const onboardingDoneKey = 'onboarding_complete';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _asking = false;

  static const _pages = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(cacheStoreProvider).setBool(onboardingDoneKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => const HomeShell(),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  Future<void> _allowLocation() async {
    setState(() => _asking = true);
    await ref.read(userLocationProvider.notifier).locate();
    if (mounted) await _finish();
  }

  void _next() => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final last = _page == _pages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 6, 0),
            child: Row(children: [
              const IconBadge(Icons.water_drop, size: 38, color: Colors.white, background: AppColors.primary),
              const SizedBox(width: 10),
              Text(l.appTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: () => showLanguagePicker(context, ref),
                icon: const Icon(Icons.translate),
                tooltip: l.language,
              ),
              TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                child: Text(l.onbSkip),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              for (var i = 0; i < _pages; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  width: _page == i ? 30 : 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primaryDark : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              Text(l.stepOf(_page + 1, _pages).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.muted)),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _InfoPage(icon: Icons.explore_outlined, title: l.onb1Title, body: l.onb1Body),
                _InfoPage(icon: Icons.add_location_alt_outlined, title: l.onb2Title, body: l.onb2Body, extra: l.onb3Body),
                _PermissionPage(asking: _asking, onAllow: _allowLocation, onSkip: _finish),
              ],
            ),
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: Text(l.onbNext),
              ),
            ),
        ]),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.icon, required this.title, required this.body, this.extra});

  final IconData icon;
  final String title;
  final String body;
  final String? extra;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: Center(child: IconBadge(icon, size: 76, color: Colors.white, background: AppColors.primary)),
          ),
          const SizedBox(height: 36),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.muted, height: 1.6)),
          if (extra != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.patronBg, borderRadius: BorderRadius.circular(AppRadius.button)),
              child: Row(children: [
                const Icon(Icons.military_tech_outlined, color: AppColors.patron),
                const SizedBox(width: 10),
                Expanded(child: Text(extra!, style: const TextStyle(height: 1.45))),
              ]),
            ),
          ],
        ]),
      );
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({required this.asking, required this.onAllow, required this.onSkip});

  final bool asking;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
        child: Column(children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: const Center(
              child: IconBadge(Icons.location_on_outlined, size: 72, color: Colors.white, background: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.onbAllowTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(l.onbAllowBody,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.6, fontSize: 15)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Assurance(icon: Icons.lock_outline, text: l.onbNoTracking)),
            const SizedBox(width: 10),
            Expanded(child: _Assurance(icon: Icons.verified_user_outlined, text: l.onbFifty)),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: asking ? null : onAllow,
            icon: const Icon(Icons.near_me_outlined, size: 18),
            label: Text(l.onbAllow),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TintButton(label: l.onbNotNow, icon: Icons.search, onPressed: asking ? null : onSkip),
          ),
        ]),
      ),
    );
  }
}

class _Assurance extends StatelessWidget {
  const _Assurance({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadius.button)),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3))),
        ]),
      );
}
