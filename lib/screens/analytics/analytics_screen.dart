// Ported from src/features/analytics/Analytics.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/equity.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/panel.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);

    final equity = computeEquity(store.districts);
    final lowVoiceFlagged = equity.where((e) => e.flagged).length;

    final inclusion = ((store.reports.where((r) {
                  final matches = store.districts.where((d) => d.id == r.districtId);
                  return matches.isNotEmpty && (matches.first.tribalMajority ?? false);
                }).length /
                (store.reports.isEmpty ? 1 : store.reports.length)) *
            100)
        .round();

    final duplicatesMerged = store.masterIssues.where((mi) => mi.repeatCount > 0).length;
    final delivery = ((store.projects
                    .where((p) => ['deployed', 'community-validated', 'scaled'].contains(p.stage))
                    .length /
                (store.projects.isEmpty ? 1 : store.projects.length)) *
            100)
        .round();
    final positiveQr = store.projects.expand((p) => p.qrFeedback).toList();
    final trust =
        ((positiveQr.where((f) => f.outcome == 'works').length / (positiveQr.isEmpty ? 1 : positiveQr.length)) * 100)
            .round();
    final reuse = store.failureLessons.length + store.projects.where((p) => p.stage == 'scaled').length;

    final panels = [
      (label: t('analyticsPage.panels.inclusion.label'), detail: t('analyticsPage.panels.inclusion.detail'), value: '$inclusion%'),
      (label: t('analyticsPage.panels.efficiency.label'), detail: t('analyticsPage.panels.efficiency.detail'), value: '$duplicatesMerged'),
      (label: t('analyticsPage.panels.delivery.label'), detail: t('analyticsPage.panels.delivery.detail'), value: '$delivery%'),
      (label: t('analyticsPage.panels.trust.label'), detail: t('analyticsPage.panels.trust.detail'), value: '${trust.isNaN ? 0 : trust}%'),
      (label: t('analyticsPage.panels.reuse.label'), detail: t('analyticsPage.panels.reuse.detail'), value: '$reuse'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t('analyticsPage.heading'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: panels
                .map((p) => Panel(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CivixColors.neel)),
                          const SizedBox(height: 4),
                          Text(p.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(p.detail, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft), textAlign: TextAlign.center),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Panel(child: Text(t('analyticsPage.lowVoiceFlagged', {'count': '$lowVoiceFlagged'}), style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
