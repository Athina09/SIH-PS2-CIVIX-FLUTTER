// Ported from src/features/citizen/MyReports.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engines/chain.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';
import '../../widgets/signature/case_thread.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final myReports = store.reports.where((r) => r.reporterName == persona.name).toList();
    final myIssueIds = myReports.map((r) => r.masterIssueId).toSet();
    final myIssues = store.masterIssues.where((mi) => myIssueIds.contains(mi.id)).toList();

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('myReports.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (myIssues.isEmpty) Text(t('myReports.empty'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          for (final mi in myIssues)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => context.go('/citizen/wall/${mi.id}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(mi.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                          if (mi.stage == 'awaiting-validation') AIBadge(label: t('myReports.aiReviewing')),
                        ],
                      ),
                      Text(mi.village, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      const SizedBox(height: 8),
                      CaseThread(currentStep: chainStep(mi, _projectFor(store, mi.projectId))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Project? _projectFor(CivixState store, String? projectId) {
    if (projectId == null) return null;
    for (final p in store.projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }
}
