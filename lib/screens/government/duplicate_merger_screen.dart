// Ported from src/features/government/DuplicateMerger.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/similarity.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

class DuplicateMergerScreen extends ConsumerStatefulWidget {
  const DuplicateMergerScreen({super.key});

  @override
  ConsumerState<DuplicateMergerScreen> createState() => _DuplicateMergerScreenState();
}

class _DuplicateMergerScreenState extends ConsumerState<DuplicateMergerScreen> {
  final Set<String> dismissed = {};

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final role = Theme.of(context).colorScheme.primary;

    final candidates = <({MasterIssue a, MasterIssue b, SimilarityResult sim})>[];
    for (var i = 0; i < store.masterIssues.length; i++) {
      for (var j = i + 1; j < store.masterIssues.length; j++) {
        final a = store.masterIssues[i];
        final b = store.masterIssues[j];
        if (a.stage == 'closed-failed' || b.stage == 'closed-failed') continue;
        if (dismissed.contains(a.id + b.id)) continue;
        final sim = similarity(category: a.category, lat: a.lat, lng: a.lng, createdAt: a.createdAt, issue: b);
        if (sim.score >= 0.55) candidates.add((a: a, b: b, sim: sim));
      }
    }
    candidates.sort((x, y) => y.sim.score.compareTo(x.sim.score));
    final shown = candidates.take(8).toList();

    return Scaffold(
      appBar: GovPageHeader(title: t('duplicateMerger.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (shown.isEmpty) Panel(child: Text(t('duplicateMerger.noDuplicates'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))),
          for (final c in shown)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: c.sim.isDuplicate ? const BoxDecoration(border: Border(left: BorderSide(color: CivixColors.ember, width: 4))) : null,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _IssueCard(issue: c.a, reportsLabel: t('duplicateMerger.reports'))),
                        const SizedBox(width: 8),
                        Expanded(child: _IssueCard(issue: c.b, reportsLabel: t('duplicateMerger.reports'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _Bar(label: t('duplicateMerger.meaning'), value: c.sim.categoryMatch.toDouble(), color: role)),
                        const SizedBox(width: 8),
                        Expanded(child: _Bar(label: t('duplicateMerger.distance'), value: c.sim.distanceScore, color: role)),
                        const SizedBox(width: 8),
                        Expanded(child: _Bar(label: t('duplicateMerger.time'), value: c.sim.timeScore, color: role)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t('duplicateMerger.similarity')} ${(c.sim.score * 100).round()}% — ${c.sim.explanation.join('; ')}',
                      style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CivixButton(
                          label: t('duplicateMerger.mergeIntoMaster'),
                          size: CivixButtonSize.sm,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                content: Text(t('duplicateMerger.mergeConfirm', {'a': c.a.title, 'b': c.b.title})),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
                                ],
                              ),
                            );
                            if (confirmed ?? false) notifier.mergeIssues(c.a.id, c.b.id, persona.name);
                          },
                        ),
                        const SizedBox(width: 8),
                        CivixButton(
                          label: t('duplicateMerger.notADuplicate'),
                          variant: CivixButtonVariant.secondary,
                          size: CivixButtonSize.sm,
                          onPressed: () => setState(() => dismissed.add(c.a.id + c.b.id)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final MasterIssue issue;
  final String reportsLabel;
  const _IssueCard({required this.issue, required this.reportsLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${issue.village} · ${issue.reportIds.length} $reportsLabel', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Bar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: CivixColors.neelSoft)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: CivixColors.rule, valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }
}
