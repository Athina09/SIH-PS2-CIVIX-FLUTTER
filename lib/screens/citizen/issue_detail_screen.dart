// Ported from src/features/citizen/IssueDetail.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../engines/chain.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/merged_badge.dart';
import '../../widgets/panel.dart';
import '../../widgets/signature/case_thread.dart';

class IssueDetailScreen extends ConsumerWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    MasterIssue? issue;
    for (final mi in store.masterIssues) {
      if (mi.id == issueId) issue = mi;
    }

    if (issue == null) {
      return Scaffold(appBar: const CivixTopBar(), body: Center(child: Text(t('issueDetail.notFound'))));
    }

    final issueReports = store.reports.where((r) => issue!.reportIds.contains(r.id)).toList();
    Project? project;
    for (final p in store.projects) {
      if (p.id == issue.projectId) project = p;
    }

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(issue.title, style: Theme.of(context).textTheme.titleLarge),
              MergedBadge(count: issue.reportIds.length),
            ],
          ),
          Text('${issue.village} · ${issue.households} households · ${issue.upvotes} upvotes', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
          const SizedBox(height: 16),
          CaseThread(currentStep: chainStep(issue, project)),
          const SizedBox(height: 16),
          Row(
            children: [
              CivixButton(
                label: '▲ ${t('issueDetail.upvote')}',
                variant: CivixButtonVariant.secondary,
                size: CivixButtonSize.sm,
                onPressed: () => notifier.upvoteIssue(issue!.id, persona.id),
              ),
              const SizedBox(width: 8),
              CivixButton(
                label: t('issueDetail.addAffectedHousehold'),
                variant: CivixButtonVariant.secondary,
                size: CivixButtonSize.sm,
                onPressed: () => notifier.addHouseholds(issue!.id, 1),
              ),
            ],
          ),
          if (issue.problemStatement != null) ...[
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('issueDetail.problemStatement'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(issue.problemStatement!.summary, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${t('issueDetail.urgency')}: ${issue.problemStatement!.urgency}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                ],
              ),
            ),
          ],
          if (project != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: CivixColors.sal, width: 4))),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t('issueDetail.linkedProject')}: ${project.title}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${t('issueDetail.stage')}: ${project.stage.replaceAll('-', ' ')}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => context.go('/projects/${project!.id}'),
                      child: Text(t('issueDetail.viewProjectRecord'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('${t('issueDetail.evidenceAndReports')} (${issueReports.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in issueReports)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.channel} · ${DateFormat('d MMM yyyy').format(DateTime.tryParse(r.createdAt) ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    const SizedBox(height: 4),
                    Text(r.translation ?? r.rawText ?? r.transcript ?? '', style: const TextStyle(fontSize: 13)),
                    for (final e in r.evidence)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () => _showEvidence(context, e),
                          child: Text('📎 ${e.label}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft, decoration: TextDecoration.underline)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEvidence(BuildContext context, Evidence e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(e.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kind: ${e.kind}'),
            Text('Added by: ${e.addedBy}'),
            if (e.duplicateStatus != null) Text('Duplicate check: ${e.duplicateStatus}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
