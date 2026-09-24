// Ported from src/features/university/ChallengeDetail.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engines/lessons.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String issueId;
  const ChallengeDetailScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);

    final issueMatch = store.masterIssues.where((mi) => mi.id == issueId);
    if (issueMatch.isEmpty) {
      return Scaffold(
        appBar: const CivixTopBar(),
        body: Center(child: Text(t('challengeDetail.notFound'))),
      );
    }
    final issue = issueMatch.first;
    final issueReports = store.reports.where((r) => issue.reportIds.contains(r.id)).toList();
    final warnings = lessonsForCategory(issue.category, store.failureLessons);
    final suggestions = store.solutionMemory.where((s) => s.category == issue.category).toList();
    final quoted = issueReports.where((r) => r.translation != null || r.rawText != null || r.transcript != null).toList();

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(issue.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          if (issue.problemStatement != null) ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('challengeDetail.problemStatement'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(issue.problemStatement!.summary, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${t('challengeDetail.successCriteria')} ${issue.problemStatement!.successCriteria.join('; ')}',
                    style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('challengeDetail.communityVoice'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (quoted.isEmpty)
                  Text(t('challengeDetail.noQuotedStatements'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))
                else
                  for (final r in quoted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            TextSpan(text: '"${r.translation ?? r.rawText ?? r.transcript}" '),
                            TextSpan(
                              text: '— ${r.reporterName}, ${r.village}',
                              style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (warnings.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: CivixColors.ember, width: 4)),
              ),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('challengeDetail.failurePreventionWarnings'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final w in warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.designWarning, style: const TextStyle(fontSize: 13, color: CivixColors.ember)),
                            Text('${t('challengeDetail.basedOn')} ${w.lesson}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (suggestions.isNotEmpty) ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('challengeDetail.solutionMemorySuggestions'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final s in suggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CivixColors.sal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('ADAPT', style: TextStyle(fontSize: 11, color: CivixColors.sal)),
                              ),
                            ],
                          ),
                          Text(s.pilotResult, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          CivixButton(
            label: t('challengeDetail.formATeam'),
            onPressed: () => context.go('/uni/team-builder/${issue.id}'),
          ),
        ],
      ),
    );
  }
}
