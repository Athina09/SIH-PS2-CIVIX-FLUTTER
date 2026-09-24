// Ported from src/features/citizen/CitizenHome.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/types.dart';
import '../../engines/chain.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';
import '../../widgets/signature/case_thread.dart';
import '../../widgets/speak_button.dart';

class CitizenHomeScreen extends ConsumerWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final myReports = store.reports.where((r) => r.reporterName == persona.name).toList();
    final myIssues = store.masterIssues.where((mi) => myReports.any((r) => r.masterIssueId == mi.id)).toList();
    final nearby = store.masterIssues.where((mi) => mi.districtId == persona.districtId).take(4).toList();
    final unread = store.notifications.where((n) => n.toRole == store.session.role && !n.read).length;
    final seasonBanner = t('citizenHome.seasonBanner.${store.season}');

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${t('citizenHome.greeting')}, ${persona.name}', style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(t('citizenHome.heading'), style: Theme.of(context).textTheme.headlineSmall)),
              SpeakButton(text: t('citizenHome.heading')),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            child: Row(
              children: [
                Expanded(child: Text(seasonBanner, style: const TextStyle(fontSize: 13))),
                SpeakButton(text: seasonBanner),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CivixButton(label: t('citizenHome.reportProblem'), onPressed: () => context.go('/citizen/report')),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('citizenHome.myReports'), style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: () => context.go('/citizen/my-reports'), child: Text(t('citizenHome.seeAll'))),
            ],
          ),
          if (myIssues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t('citizenHome.noReportsYet'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
            ),
          for (final mi in myIssues.take(3)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mi.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    CaseThread(currentStep: chainStep(mi, _projectFor(store, mi.projectId))),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          Text(t('citizenHome.nearbyIssues'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final mi in nearby) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go('/citizen/wall/${mi.id}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mi.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${mi.village} · ${mi.upvotes} ${t('citizenHome.upvotes')}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _MiniTile(label: '$unread ${t('citizenHome.unreadNotifications')}', onTap: () => context.go('/notifications'))),
              const SizedBox(width: 8),
              Expanded(child: _MiniTile(label: t('citizenHome.scanProjectQr'), onTap: () => context.go('/citizen/scan'))),
            ],
          ),
          const SizedBox(height: 8),
          _MiniTile(label: t('citizenHome.socialSignalMonitoring'), onTap: () => context.go('/citizen/channels')),
        ],
      ),
    );
  }
}

Project? _projectFor(CivixState store, String? projectId) {
  if (projectId == null) return null;
  for (final p in store.projects) {
    if (p.id == projectId) return p;
  }
  return null;
}

class _MiniTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Panel(
        child: Center(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
      ),
    );
  }
}
