// Ported from src/features/university/UniHome.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engines/ranking.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';

class UniHomeScreen extends ConsumerStatefulWidget {
  const UniHomeScreen({super.key});

  @override
  ConsumerState<UniHomeScreen> createState() => _UniHomeScreenState();
}

class _UniHomeScreenState extends ConsumerState<UniHomeScreen> {
  String? reportFor;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final institutions = store.institutions;
    final inst = institutions.firstWhere(
      (i) => i.id == persona.institutionId,
      orElse: () => institutions.first,
    );

    final innovationIssues =
        store.masterIssues.where((mi) => mi.stage == 'routed-innovation' && mi.problemStatement != null).toList();
    final matched = innovationIssues
        .map((mi) {
          final ranked = topInstitutions(mi.problemStatement!.disciplinesNeeded, mi.lat, mi.lng, [inst], n: 1);
          final score = ranked.isNotEmpty ? ranked.first.score : 0.0;
          return (mi: mi, score: score);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final myProjects = store.projects.where((p) => p.ownerId == inst.id).toList();
    final myTasks = store.outreachTasks.where((task) => task.institutionId == inst.id).toList();

    // Issues where another institution's project was chosen instead of this one, restricted to
    // challenges this university could plausibly have taken (some discipline overlap on record).
    final awardedElsewhere = store.projects
        .where((p) => p.ownerId != inst.id)
        .map((p) {
          final miMatch = store.masterIssues.where((m) => m.id == p.issueId);
          final winnerMatch = institutions.where((i) => i.id == p.ownerId);
          if (miMatch.isEmpty || miMatch.first.problemStatement == null || winnerMatch.isEmpty) return null;
          final mi = miMatch.first;
          final winnerInst = winnerMatch.first;
          final ranked = rankInstitutions(mi.problemStatement!.disciplinesNeeded, mi.lat, mi.lng, institutions);
          final winnerRankedList = ranked.where((r) => r.institution.id == winnerInst.id);
          final candidateRankedList = ranked.where((r) => r.institution.id == inst.id);
          if (winnerRankedList.isEmpty || candidateRankedList.isEmpty) return null;
          final winnerRanked = winnerRankedList.first;
          final candidateRanked = candidateRankedList.first;
          if (candidateRanked.factors.expertise == 0) return null;
          return (mi: mi, project: p, winnerRanked: winnerRanked, candidateRanked: candidateRanked);
        })
        .whereType<({MasterIssue mi, Project project, RankedInstitution winnerRanked, RankedInstitution candidateRanked})>()
        .toList()
      ..sort((a, b) => b.candidateRanked.score.compareTo(a.candidateRanked.score));

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(inst.name, style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 4),
          Text(t('uniHome.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _StatTile(value: '${matched.length}', label: t('uniHome.matchedChallenges'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '${myProjects.length}', label: t('uniHome.myProjects'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: inst.credibility.overall.round().toString(), label: t('uniHome.credibility'))),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(t('uniHome.challengesMatchedToYou'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              AIBadge(label: t('uniHome.aiRankedByDiscipline')),
            ],
          ),
          const SizedBox(height: 8),
          if (matched.isEmpty)
            Text(t('uniHome.noValidatedChallenges'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))
          else
            for (final m in matched) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => context.go('/uni/challenges/${m.mi.id}'),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.mi.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          t('uniHome.matchScore', {'pct': (m.score * 100).toStringAsFixed(0)}),
                          style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          const SizedBox(height: 24),

          if (awardedElsewhere.isNotEmpty) ...[
            Row(
              children: [
                Text(t('uniHome.opportunitiesMatchedElsewhere'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                AIBadge(label: t('uniHome.aiRankedSameScoring')),
              ],
            ),
            const SizedBox(height: 8),
            for (final entry in awardedElsewhere) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                                Text(entry.mi.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                                    children: [
                                      TextSpan(text: '${t('uniHome.chosen')} '),
                                      TextSpan(
                                        text: entry.winnerRanked.institution.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel),
                                      ),
                                      TextSpan(
                                        text: ' · ${t('uniHome.yourMatchVsTheirs', {
                                              'yours': (entry.candidateRanked.score * 100).toStringAsFixed(0),
                                              'theirs': (entry.winnerRanked.score * 100).toStringAsFixed(0),
                                            })}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CivixButton(
                            label: reportFor == entry.mi.id ? t('uniHome.hideAiReport') : t('uniHome.getAiReport'),
                            variant: CivixButtonVariant.secondary,
                            size: CivixButtonSize.sm,
                            onPressed: () => setState(() => reportFor = reportFor == entry.mi.id ? null : entry.mi.id),
                          ),
                        ],
                      ),
                      if (reportFor == entry.mi.id) ...[
                        const Divider(height: 24),
                        Builder(builder: (context) {
                          final explanation = explainSelection(entry.winnerRanked, entry.candidateRanked);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(explanation.summary, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 8),
                              for (final f in explanation.factors) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: Text(f.label, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                                      ),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          '${t('uniHome.you')} ${(f.candidate * 100).round()}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: f.edge == 'candidate' ? CivixColors.sal : CivixColors.neel,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: (f.candidate > f.winner ? f.candidate : f.winner).clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: CivixColors.chuna,
                                            valueColor: AlwaysStoppedAnimation(roleColorOf(store.session.role)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          '${entry.winnerRanked.institution.name.split(' ').first} ${(f.winner * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: f.edge == 'winner' ? CivixColors.ember : CivixColors.neel,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (explanation.improvement != null) ...[
                                const SizedBox(height: 4),
                                Text(explanation.improvement!, style: const TextStyle(fontSize: 11, color: CivixColors.sal)),
                              ],
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],

          if (myTasks.isNotEmpty) ...[
            Text(t('uniHome.outreachTasks'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final task in myTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  child: Text(
                    t('uniHome.districtOutreach', {'district': task.districtId, 'status': task.status}),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],

          Text(t('uniHome.myProjects'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in myProjects)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go('/projects/${p.id}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(p.stage.replaceAll('-', ' '), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CivixColors.neel)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ],
      ),
    );
  }
}
