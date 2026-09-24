// Ported from src/features/government/ControlRoom.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../i18n/dictionary.dart';
import '../../state/a11y_store.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

const _seasons = ['summer', 'monsoon', 'post-monsoon', 'winter'];

class ControlRoomScreen extends ConsumerWidget {
  const ControlRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final dataSaver = ref.watch(a11yStoreProvider).dataSaver;

    final recentCutoff = DateTime.now().subtract(const Duration(days: 3));
    final kpis = [
      (t('controlRoom.kpis.newSignalsToday'), store.masterIssues.where((i) => DateTime.parse(i.createdAt).isAfter(recentCutoff)).length),
      (t('controlRoom.kpis.awaitingValidation'), store.masterIssues.where((i) => i.stage == 'awaiting-validation').length),
      (t('controlRoom.kpis.routedToServices'), store.masterIssues.where((i) => i.stage == 'routed-service').length),
      (t('controlRoom.kpis.inInnovation'), store.masterIssues.where((i) => i.stage == 'routed-innovation' || i.stage == 'in-project').length),
      (t('controlRoom.kpis.overdueMilestones'), store.projects.expand((p) => p.milestones).where((m) => m.status == 'pending' && DateTime.parse(m.due).isBefore(DateTime.now())).length),
      (t('controlRoom.kpis.capabilityGaps'), store.capabilityGaps.where((g) => g.filledBy == null).length),
      (t('controlRoom.kpis.communityConfirmed'), store.projects.expand((p) => p.qrFeedback).where((f) => f.outcome == 'works').length),
    ];

    final needsAction = store.masterIssues.where((i) => i.stage == 'awaiting-validation').take(5).toList();
    final mapIssues = store.masterIssues.where((mi) => mi.stage != 'closed-failed').toList();

    return Scaffold(
      appBar: GovPageHeader(title: t('controlRoom.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final k in kpis)
                Panel(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${k.$2}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CivixColors.neel)),
                        const SizedBox(height: 4),
                        Text(k.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('controlRoom.issueMap'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (dataSaver)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: CivixColors.chuna, borderRadius: BorderRadius.circular(8)),
                    child: Text(t('controlRoom.mapHiddenDataSaver'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                  )
                else
                  Column(
                    children: [
                      for (final mi in mapIssues.take(8))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_outlined, color: CivixColors.neel),
                          title: Text(mi.title, style: const TextStyle(fontSize: 13)),
                          subtitle: Text('${mi.village} · ${mi.lat.toStringAsFixed(3)}, ${mi.lng.toStringAsFixed(3)}', style: const TextStyle(fontSize: 11)),
                          onTap: () => context.go('/gov/issues/${mi.id}'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('controlRoom.seasonControl'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _seasons)
                      ChoiceChip(
                        label: Text(s.replaceAll('-', ' ')),
                        selected: store.season == s,
                        onSelected: (_) => notifier.setSeason(s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${t('controlRoom.rainfallAnomaly')}: ${store.rainfallAnomalyPct.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Slider(
                  min: -50,
                  max: 50,
                  value: store.rainfallAnomalyPct.clamp(-50, 50),
                  onChanged: (v) => notifier.setRainfallAnomaly(v),
                ),
                Row(
                  children: [
                    Checkbox(value: store.drought, onChanged: (v) => notifier.setDrought(v ?? false)),
                    Text(t('controlRoom.droughtFlag'), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('controlRoom.whatNeedsAction'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final i in needsAction)
                  InkWell(
                    onTap: () => context.go('/gov/issues/${i.id}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                      child: Text(i.title, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('controlRoom.recentAuditEntries'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final a in store.auditLog.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.action, style: const TextStyle(fontSize: 13)),
                        Text('${a.actor} · ${DateFormat('d MMM').format(DateTime.parse(a.at))}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        const Divider(height: 12),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
