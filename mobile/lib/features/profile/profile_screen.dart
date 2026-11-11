// Account tab: trust score, numbers, links and settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/language_picker.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../home/home_shell.dart';
import 'delete_account_dialog.dart';
import 'leaderboard_screen.dart';
import 'profile_repository.dart';

({String label, IconData icon, Color color}) trustLevel(AppLocalizations l, int score) {
  if (score >= 1000) return (label: l.levelChampion, icon: Icons.diamond_outlined, color: AppColors.patron);
  if (score >= trustedThreshold) return (label: l.levelVerified, icon: Icons.verified, color: AppColors.working);
  if (score >= 250) return (label: l.levelTrusted, icon: Icons.star_outline, color: AppColors.pending);
  if (score >= 100) return (label: l.levelContributor, icon: Icons.handshake_outlined, color: AppColors.primary);
  return (label: l.levelNewcomer, icon: Icons.eco_outlined, color: AppColors.muted);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.navAccount)),
      body: session.isLoggedIn ? const _SignedIn() : const _SignedOut(),
    );
  }
}

class _SignedOut extends ConsumerWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListView(padding: const EdgeInsets.all(16), children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconBadge(Icons.person_outline,
                size: 48, background: AppColors.primaryContainer, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(l.authTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.authSubtitle, style: const TextStyle(color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ensureLoggedIn(context, ref),
            child: Text(l.guestLogin),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      SectionLabel(l.preferences),
      const AppCard(padding: EdgeInsets.zero, child: _SettingsRows()),
      const SizedBox(height: 16),
      const _MissionCard(),
    ]);
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(sessionProvider).profile;
    final stats = ref.watch(myStatsProvider);

    Future<void> refresh() async {
      ref.invalidate(myStatsProvider);
      await ref.read(sessionProvider.notifier).refreshProfile();
    }

    final s = stats.value;
    // The session's score is updated the moment points are earned.
    final score = profile?.trustScore ?? s?.trustScore ?? 0;
    final level = trustLevel(l, score);
    final remaining = trustedThreshold - score;

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
        Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              (profile?.username.characters.first ?? '?').toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile?.username ?? '…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Pill(
                text: level.label,
                color: level.color,
                background: level.color.withValues(alpha: 0.12),
                icon: level.icon,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const IconBadge(Icons.shield_outlined,
                  background: AppColors.primaryContainer, color: AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.trustScore, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(l.trustTrack, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ]),
              ),
              Text.rich(TextSpan(children: [
                TextSpan(
                  text: '$score',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
                const TextSpan(text: ' / $trustedThreshold', style: TextStyle(color: AppColors.muted)),
              ])),
            ]),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (score / trustedThreshold).clamp(0, 1).toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(children: [
                const Icon(Icons.bolt, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remaining > 0 ? l.pointsUntilTrusted(remaining) : l.trustedNote,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _Stat(icon: Icons.add_location_alt_outlined, value: s?.coolersApproved, label: l.statCoolers),
          const SizedBox(width: 10),
          _Stat(icon: Icons.how_to_reg_outlined, value: s?.confirmations, label: l.statConfirmations),
          const SizedBox(width: 10),
          _Stat(icon: Icons.photo_camera_outlined, value: s?.photos, label: l.statPhotos),
        ]),
        const SizedBox(height: 8),
        SectionLabel(l.myActivity),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _Row(
              icon: Icons.water_drop_outlined,
              title: l.mySubmissions,
              trailing: s == null
                  ? null
                  : Pill(
                      text: '${s.coolersAdded}',
                      color: AppColors.primaryDark,
                      background: AppColors.primaryContainer,
                      icon: Icons.add_location_alt_outlined,
                    ),
              onTap: () => ref.read(homeTabProvider.notifier).go(1),
            ),
            const Divider(indent: 68),
            _Row(
              icon: Icons.emoji_events_outlined,
              title: l.leaderboard,
              trailing: s?.rank == null
                  ? null
                  : Pill(
                      text: l.rankValue(s!.rank!),
                      color: AppColors.patron,
                      background: AppColors.patronBg,
                      icon: Icons.military_tech_outlined,
                    ),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        SectionLabel(l.preferences),
        const AppCard(padding: EdgeInsets.zero, child: _SettingsRows()),
        const SizedBox(height: 16),
        const _MissionCard(),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: Text(l.logout),
          style: TextButton.styleFrom(foregroundColor: AppColors.broken),
        ),
        TextButton(
          onPressed: () async {
            final deleted = await showDeleteAccountDialog(context);
            if (deleted && context.mounted) showSnack(context, l.deleteAccountDone);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: Text(l.deleteAccount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ),
      ]),
    );
  }
}

/// Language and privacy: available with or without an account.
class _SettingsRows extends ConsumerWidget {
  const _SettingsRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(children: [
      _Row(
        icon: Icons.translate,
        title: l.language,
        subtitle: switch (ref.watch(localeProvider)?.languageCode) {
          'ar' => l.languageArabic,
          'en' => l.languageEnglish,
          _ => l.languageSystem,
        },
        onTap: () => showLanguagePicker(context, ref),
      ),
      const Divider(indent: 68),
      _Row(
        icon: Icons.privacy_tip_outlined,
        title: l.privacyPolicy,
        trailingIcon: Icons.open_in_new,
        onTap: () async {
          var opened = false;
          try {
            opened = await launchUrl(Uri.parse(AppConfig.absoluteUrl('/privacy')),
                mode: LaunchMode.externalApplication);
          } catch (_) {}
          if (!opened && context.mounted) showSnack(context, l.errOpenLink, error: true);
        },
      ),
    ]);
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      color: AppColors.primaryContainer,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const IconBadge(Icons.volunteer_activism_outlined, color: Colors.white, background: AppColors.primaryDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.missionTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            const SizedBox(height: 4),
            Text(l.missionBody, style: const TextStyle(color: AppColors.primaryDark, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(children: [
            Icon(icon, color: AppColors.primaryDark),
            const SizedBox(height: 6),
            Text(value == null ? '–' : '$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3)),
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.trailingIcon = Icons.chevron_right,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            IconBadge(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            Icon(trailingIcon, color: AppColors.muted, size: 20),
          ]),
        ),
      );
}
