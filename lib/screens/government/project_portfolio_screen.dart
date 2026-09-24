// Ported from src/features/government/ProjectPortfolio.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';
import '../../widgets/status_chip.dart';

class ProjectPortfolioScreen extends ConsumerWidget {
  const ProjectPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    return Scaffold(
      appBar: GovPageHeader(title: t('projectPortfolio.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in store.projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => context.go('/projects/${p.id}'),
                                child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, decoration: TextDecoration.underline)),
                              ),
                              Text(
                                '${store.institutions.where((i) => i.id == p.ownerId).firstOrNull?.name ?? ''} · ${formatCurrency(p.budget)}',
                                style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                              ),
                            ],
                          ),
                        ),
                        Builder(builder: (context) {
                          final overdue = p.milestones.where((m) => m.status == 'pending' && DateTime.parse(m.due).isBefore(DateTime.now())).length;
                          return StatusChip(
                            label: p.stage.replaceAll('-', ' '),
                            tone: p.stage == 'failed' ? ChipTone.failed : (overdue > 0 ? ChipTone.risk : ChipTone.progress),
                          );
                        }),
                      ],
                    ),
                    Builder(builder: (context) {
                      final overdue = p.milestones.where((m) => m.status == 'pending' && DateTime.parse(m.due).isBefore(DateTime.now())).toList();
                      if (overdue.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(t('projectPortfolio.milestonesOverdue', {'count': '${overdue.length}'}), style: const TextStyle(fontSize: 11, color: CivixColors.ember)),
                      );
                    }),
                    for (final m in p.milestones.where((m) => m.status == 'submitted'))
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('${m.title} — ${t('projectPortfolio.proofSubmitted')}', style: const TextStyle(fontSize: 13))),
                                if (m.proof != null) AIBadge(label: _proofLabel(t, m.proof!)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (m.proof != null)
                                  CivixButton(
                                    label: t('projectPortfolio.viewEvidenceAndSummary'),
                                    variant: CivixButtonVariant.secondary,
                                    size: CivixButtonSize.sm,
                                    onPressed: () => _showDoc(context, m.proof!, p, store),
                                  ),
                                CivixButton(
                                  label: t('projectPortfolio.approveMilestone'),
                                  size: CivixButtonSize.sm,
                                  onPressed: () async {
                                    if (m.proof?.duplicateStatus == 'duplicate') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          content: Text(t('projectPortfolio.approveDuplicateConfirm')),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
                                          ],
                                        ),
                                      );
                                      if (!(confirmed ?? false)) return;
                                    }
                                    notifier.approveMilestone(p.id, m.id, persona.name);
                                  },
                                ),
                              ],
                            ),
                          ],
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

  String _proofLabel(AppDictionary t, Doc proof) {
    if (proof.duplicateStatus == 'duplicate') return '⚠ ${t('projectPortfolio.aiFlaggedDuplicate')}';
    if (proof.contentHash != null || proof.duplicateCheckConfidence != null) {
      final pct = proof.duplicateCheckConfidence != null ? ' (${(proof.duplicateCheckConfidence! * 100).round()}%)' : '';
      return '✓ ${t('projectPortfolio.aiVerifiedUnique')}$pct';
    }
    return t('projectPortfolio.aiCheckNotRun');
  }

  void _showDoc(BuildContext context, Doc doc, Project project, CivixState store) {
    final owner = store.institutions.where((i) => i.id == project.ownerId).firstOrNull;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc.title),
        content: Text('${doc.kind} · ${project.title}${owner != null ? ' · ${owner.name}' : ''}${doc.duplicateStatus != null ? '\nAI status: ${doc.duplicateStatus}' : ''}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
