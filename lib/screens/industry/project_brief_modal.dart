// Ported from src/features/industry/ProjectBriefModal.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gov_contacts.dart';
import '../../engines/industry_relevance.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/panel.dart';
import '../../widgets/status_chip.dart';

ChipTone _milestoneTone(String status) {
  switch (status) {
    case 'submitted':
    case 'approved':
      return ChipTone.progress;
    case 'released':
      return ChipTone.success;
    default:
      return ChipTone.neutral;
  }
}

ChipTone _severityTone(String severity) {
  switch (severity) {
    case 'medium':
      return ChipTone.risk;
    case 'high':
      return ChipTone.failed;
    default:
      return ChipTone.neutral;
  }
}

class ProjectBriefModal extends ConsumerWidget {
  final Project project;
  final MasterIssue? issue;
  final Institution? owner;
  final District? district;
  final IndustryPartner partner;
  final void Function(String milestoneId, double budget, String title) onSupportMilestone;
  final VoidCallback onSupportProject;

  const ProjectBriefModal({
    super.key,
    required this.project,
    this.issue,
    this.owner,
    this.district,
    required this.partner,
    required this.onSupportMilestone,
    required this.onSupportProject,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    MasterIssue? issue,
    Institution? owner,
    District? district,
    required IndustryPartner partner,
    required void Function(String milestoneId, double budget, String title) onSupportMilestone,
    required VoidCallback onSupportProject,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ProjectBriefModal(
        project: project,
        issue: issue,
        owner: owner,
        district: district,
        partner: partner,
        onSupportMilestone: onSupportMilestone,
        onSupportProject: onSupportProject,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final relevance = scoreRelevance(partner, project, issue?.category);
    final contact = district != null ? govContactForDistrict(district!.id, district!.name) : null;
    final totalPledged = project.pledges.fold<double>(0, (s, p) => s + (p.amount ?? 0));
    final totalReleased = project.pledges
        .where((p) => p.status == 'released')
        .fold<double>(0, (s, p) => s + (p.amount ?? 0));
    final fundedPct = project.budget > 0 ? (totalPledged / project.budget * 100).clamp(0, 100).round() : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CivixColors.rule))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(project.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CivixColors.neel)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: t('projectBriefModal.close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          label: project.stage.replaceAll('-', ' '),
                          tone: project.stage == 'failed' ? ChipTone.failed : ChipTone.progress,
                        ),
                        Text('${owner?.name ?? ''} · ${district?.name ?? ''}',
                            style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Panel(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AIBadge(
                              label: t('projectBriefModal.matchToCsrProfile', {'pct': '${(relevance.score * 100).round()}'})),
                          const SizedBox(height: 6),
                          for (final r in relevance.reasons)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('• $r', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                            ),
                        ],
                      ),
                    ),
                    if (issue?.problemStatement != null) ...[
                      const SizedBox(height: 12),
                      Text(t('projectBriefModal.problemAddressed'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                      const SizedBox(height: 2),
                      Text(issue!.problemStatement!.summary, style: const TextStyle(fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t('projectBriefModal.fundingProgress'),
                            style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                        Text(
                          t('projectBriefModal.pledgedOfBudget', {
                            'pledged': formatCurrency(totalPledged),
                            'budget': formatCurrency(project.budget),
                          }),
                          style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fundedPct / 100,
                        minHeight: 8,
                        backgroundColor: CivixColors.chuna,
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(t('projectBriefModal.alreadyReleased', {'amount': formatCurrency(totalReleased)}),
                        style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    const SizedBox(height: 16),
                    Text(t('projectBriefModal.milestones'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                    const SizedBox(height: 6),
                    for (final m in project.milestones)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: CivixColors.rule),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: project.budget > 0 ? (m.budget / project.budget).clamp(0, 1) : 0,
                                        minHeight: 5,
                                        backgroundColor: CivixColors.chuna,
                                        valueColor: const AlwaysStoppedAnimation(CivixColors.sal),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: Text(formatCurrency(m.budget),
                                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 8),
                              StatusChip(label: t('projectBriefModal.milestoneStatus.${m.status}'), tone: _milestoneTone(m.status)),
                              if (m.status == 'pending' || m.status == 'submitted') ...[
                                const SizedBox(width: 8),
                                CivixButton(
                                  label: t('projectBriefModal.fund'),
                                  size: CivixButtonSize.sm,
                                  onPressed: () => onSupportMilestone(m.id, m.budget, m.title),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (project.risks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(t('projectBriefModal.risksOnFile'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final r in project.risks) StatusChip(label: r.label, tone: _severityTone(r.severity))],
                      ),
                    ],
                    if (project.pilotResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(t('projectBriefModal.pilotResults'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            for (final m in project.pilotResults)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: CivixColors.rule))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(m.label, style: const TextStyle(fontSize: 12)),
                                    Text(
                                      '${m.value}${m.unit.isNotEmpty ? ' ${m.unit}' : ''}'
                                      '${m.target != null ? ' (${t('projectBriefModal.target')} ${m.target}${m.unit})' : ''}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.neel),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (contact != null) ...[
                      const SizedBox(height: 12),
                      Panel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('projectBriefModal.govOfficialMonitoring'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                            const SizedBox(height: 4),
                            Text(contact.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(contact.designation, style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.phone, size: 13, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(contact.phone,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                                ]),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.email_outlined, size: 13, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(contact.email,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CivixButton(label: t('projectBriefModal.supportTheFullProject'), onPressed: onSupportProject),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
