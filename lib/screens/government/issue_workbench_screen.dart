// Ported from src/features/government/IssueWorkbench.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engines/capability_gap.dart';
import '../../engines/priority.dart';
import '../../engines/ranking.dart';
import '../../engines/routing.dart' as routing_engine;
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/merged_badge.dart';
import '../../widgets/panel.dart';

const _seasons = ['summer', 'monsoon', 'post-monsoon', 'winter'];

class IssueWorkbenchScreen extends ConsumerStatefulWidget {
  final String issueId;
  const IssueWorkbenchScreen({super.key, required this.issueId});

  @override
  ConsumerState<IssueWorkbenchScreen> createState() => _IssueWorkbenchScreenState();
}

class _IssueWorkbenchScreenState extends ConsumerState<IssueWorkbenchScreen> {
  int step = 0;
  String routeType = 'service';
  String overrideReason = '';
  String? whatIfSeason;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final role = Theme.of(context).colorScheme.primary;
    whatIfSeason ??= store.season;

    final steps = t.list('issueWorkbench.steps');
    final match = store.masterIssues.where((mi) => mi.id == widget.issueId);

    return Scaffold(
      appBar: GovPageHeader(title: match.isEmpty ? t('issueWorkbench.notFound') : match.first.title),
      body: match.isEmpty
          ? Padding(padding: const EdgeInsets.all(16), child: Text(t('issueWorkbench.notFound')))
          : Builder(builder: (context) {
              final issue = match.first;
              final issueReports = store.reports.where((r) => issue.reportIds.contains(r.id)).toList();
              final priority = computePriority(
                category: issue.category,
                households: issue.households,
                upvotes: issue.upvotes,
                districtId: issue.districtId,
                districts: store.districts,
                season: whatIfSeason!,
                rainfallAnomalyPct: store.rainfallAnomalyPct,
                drought: store.drought,
              );
              final rec = routing_engine.recommendRoute(category: issue.category, repeatCount: issue.repeatCount);
              final disciplines = issue.problemStatement?.disciplinesNeeded ?? [];
              final top3 = topInstitutions(disciplines, issue.lat, issue.lng, store.institutions, n: 3);
              final gaps = detectCapabilityGaps(disciplines, top3.map((r) => r.institution).toList(), issue.category);

              return ListView(
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        ChoiceChip(
                          label: Text('${i + 1}. ${steps[i]}'),
                          selected: step == i,
                          onSelected: (_) => setState(() => step = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (step == 0)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('issueWorkbench.evidenceReview'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          for (final r in issueReports)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${r.channel} · ${r.language}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                                  const SizedBox(height: 2),
                                  Text(r.translation ?? r.rawText ?? r.transcript ?? '', style: const TextStyle(fontSize: 13)),
                                  for (final e in r.evidence)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: InkWell(
                                        onTap: () => _showEvidence(context, e),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('📎 ', style: TextStyle(fontSize: 12)),
                                            Text(e.label, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline, color: CivixColors.neelSoft)),
                                            if (e.duplicateStatus == 'duplicate') ...[
                                              const SizedBox(width: 6),
                                              _pill('⚠ ${t('issueWorkbench.aiDuplicate')}', CivixColors.ember),
                                            ],
                                            if (e.duplicateStatus == 'unique') ...[
                                              const SizedBox(width: 6),
                                              _pill('✓ ${t('issueWorkbench.aiVerified')}', CivixColors.sal),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          CivixButton(
                            label: t('issueWorkbench.validateAndGenerate'),
                            onPressed: () {
                              notifier.validateIssue(issue.id, persona.name);
                              setState(() => step = 1);
                            },
                          ),
                        ],
                      ),
                    ),

                  if (step == 1)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('issueWorkbench.problemRefinery'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (issue.problemStatement == null)
                            Text(t('issueWorkbench.validateFirst'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))
                          else ...[
                            _FieldEditor(
                              label: t('issueWorkbench.summary'),
                              value: issue.problemStatement!.summary,
                              onChanged: (v) => notifier.editProblemStatement(
                                issue.id,
                                ProblemStatement(
                                  summary: v,
                                  scope: issue.problemStatement!.scope,
                                  evidenceSummary: issue.problemStatement!.evidenceSummary,
                                  urgency: issue.problemStatement!.urgency,
                                  successCriteria: issue.problemStatement!.successCriteria,
                                  disciplinesNeeded: issue.problemStatement!.disciplinesNeeded,
                                ),
                                persona.name,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _FieldEditor(
                              label: t('issueWorkbench.scope'),
                              value: issue.problemStatement!.scope,
                              onChanged: (v) => notifier.editProblemStatement(
                                issue.id,
                                ProblemStatement(
                                  summary: issue.problemStatement!.summary,
                                  scope: v,
                                  evidenceSummary: issue.problemStatement!.evidenceSummary,
                                  urgency: issue.problemStatement!.urgency,
                                  successCriteria: issue.problemStatement!.successCriteria,
                                  disciplinesNeeded: issue.problemStatement!.disciplinesNeeded,
                                ),
                                persona.name,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${t('issueWorkbench.urgency')}: ${issue.problemStatement!.urgency}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                            Text('${t('issueWorkbench.disciplinesNeeded')}: ${issue.problemStatement!.disciplinesNeeded.join(', ')}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                            const SizedBox(height: 8),
                            CivixButton(label: t('issueWorkbench.continue'), size: CivixButtonSize.sm, onPressed: () => setState(() => step = 2)),
                          ],
                        ],
                      ),
                    ),

                  if (step == 2)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('issueWorkbench.priority'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: [
                              _barBox(t('issueWorkbench.harm'), priority.harm, 30, role),
                              _barBox(t('issueWorkbench.people'), priority.people, 25, role),
                              _barBox(t('issueWorkbench.equityGap'), priority.equityGap, 20, role),
                              _barBox(t('issueWorkbench.seasonal'), priority.seasonal, 25, role),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: CivixColors.neel),
                              children: [
                                TextSpan(text: '${priority.total.round()} ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const TextSpan(text: '/ 100', style: TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(t('issueWorkbench.whyThisScore'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            children: [
                              for (final e in priority.explanation)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(e, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: DropdownButton<String>(
                                  value: whatIfSeason,
                                  items: [for (final s in _seasons) DropdownMenuItem(value: s, child: Text(s))],
                                  onChanged: (v) => setState(() => whatIfSeason = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CivixButton(
                            label: t('issueWorkbench.continueToRouting'),
                            size: CivixButtonSize.sm,
                            onPressed: () => setState(() {
                              routeType = rec.type;
                              step = 3;
                            }),
                          ),
                        ],
                      ),
                    ),

                  if (step == 3)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('issueWorkbench.routingDecision'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: CivixColors.neel, fontSize: 13),
                              children: [
                                TextSpan(text: '${t('issueWorkbench.aiRecommended')} '),
                                TextSpan(text: rec.type == 'service' ? t('issueWorkbench.serviceTwin') : t('issueWorkbench.innovationTwin'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' — ${rec.reason}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => routeType = 'service'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: routeType == 'service' ? CivixColors.neel.withValues(alpha: 0.1) : null,
                                    side: BorderSide(color: routeType == 'service' ? CivixColors.neel : CivixColors.rule),
                                  ),
                                  child: Text(t('issueWorkbench.serviceTwin')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => routeType = 'innovation'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: routeType == 'innovation' ? CivixColors.sal.withValues(alpha: 0.1) : null,
                                    side: BorderSide(color: routeType == 'innovation' ? CivixColors.sal : CivixColors.rule),
                                  ),
                                  child: Text(t('issueWorkbench.innovationTwin')),
                                ),
                              ),
                            ],
                          ),
                          if (routeType != rec.type) ...[
                            const SizedBox(height: 12),
                            Text(t('issueWorkbench.overrideReason'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              onChanged: (v) => setState(() => overrideReason = v),
                            ),
                          ],
                          const SizedBox(height: 12),
                          CivixButton(
                            label: t('issueWorkbench.confirmRouting'),
                            size: CivixButtonSize.sm,
                            onPressed: (routeType != rec.type && overrideReason.trim().isEmpty)
                                ? null
                                : () {
                                    notifier.routeIssue(
                                      issue.id,
                                      type: routeType,
                                      department: rec.department,
                                      scheme: rec.scheme,
                                      overrideReason: overrideReason.isEmpty ? null : overrideReason,
                                      actor: persona.name,
                                    );
                                    if (routeType == 'innovation') {
                                      setState(() => step = 4);
                                    } else {
                                      context.go('/gov/services');
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),

                  if (step == 4)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('issueWorkbench.teamRankingForInnovation'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          for (var i = 0; i < top3.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${i + 1} ${top3[i].institution.name}  ${t('issueWorkbench.score')} ${(top3[i].score * 100).round()}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      for (final k in ['expertise', 'lab', 'location', 'availability', 'credibility'])
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(k, style: const TextStyle(fontSize: 9, color: CivixColors.neelSoft)),
                                                const SizedBox(height: 2),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(999),
                                                  child: LinearProgressIndicator(
                                                    value: top3[i].factors[k].clamp(0, 1),
                                                    minHeight: 5,
                                                    backgroundColor: CivixColors.rule,
                                                    valueColor: AlwaysStoppedAnimation(role),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (gaps.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('${t('issueWorkbench.unmetCapability')}: ${gaps.join(', ')}', style: const TextStyle(fontSize: 12, color: CivixColors.ember)),
                            ),
                          CivixButton(
                            label: t('issueWorkbench.continueToTeamFormation'),
                            onPressed: () => context.go('/uni/team-builder/${issue.id}'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
    );
  }

  static Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
      );

  static Widget _barBox(String label, double value, int weight, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$label ($weight%)', style: const TextStyle(fontSize: 10, color: CivixColors.neelSoft)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: CivixColors.rule, valueColor: AlwaysStoppedAnimation(color)),
            ),
          ],
        ),
      );

  void _showEvidence(BuildContext context, Evidence e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(e.label),
        content: Text('${e.kind} · added by ${e.addedBy}${e.duplicateStatus != null ? '\nStatus: ${e.duplicateStatus}' : ''}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _FieldEditor({required this.label, required this.value, required this.onChanged});

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final controller = TextEditingController(text: widget.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
