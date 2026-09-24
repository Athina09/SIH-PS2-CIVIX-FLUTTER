// Ported from src/features/industry/Opportunities.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/districts.dart';
import '../../engines/industry_relevance.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';
import '../../widgets/pledge_confirm_dialog.dart';
import 'project_brief_modal.dart';

const _pledgeTypes = ['funding', 'mentoring', 'equipment', 'manufacturing', 'testing'];

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  String districtFilter = 'all';
  String typeFilter = 'all';

  void _pledge(Project project, IndustryPartner partner, Pledge input) {
    ref.read(civixStoreProvider.notifier).pledgeSupport(project.id, input, partner.name);
    final district = districts.where((d) => d.id == project.districtId).toList();
    PledgeConfirmDialog.show(
      context,
      projectTitle: project.title,
      amount: input.amount,
      districtId: project.districtId,
      districtName: district.isNotEmpty ? district.first.name : project.districtId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final partnerMatches = store.partners.where((p) => p.id == persona.partnerId).toList();
    final partner = partnerMatches.isNotEmpty ? partnerMatches.first : store.partners.first;

    final needsFromMilestones = <({Project project, Milestone milestone})>[];
    for (final p in store.projects) {
      for (final m in p.milestones) {
        if (m.status == 'pending') needsFromMilestones.add((project: p, milestone: m));
      }
    }
    final gaps = store.capabilityGaps.where((g) => g.published && g.filledBy == null).toList();
    final openProjects = store.projects.where((p) => p.stage != 'failed').toList();

    RelevanceResult relevanceFor(Project p) {
      final issue = store.masterIssues.where((mi) => mi.id == p.issueId).toList();
      return scoreRelevance(partner, p, issue.isNotEmpty ? issue.first.category : null);
    }

    double totalNeeded = 0;
    for (final p in openProjects) {
      for (final m in p.milestones) {
        if (m.status == 'pending' || m.status == 'submitted') totalNeeded += m.budget;
      }
    }
    final strongMatches = openProjects.where((p) => relevanceFor(p).score >= 0.6).length;

    final filteredNeeds = needsFromMilestones
        .where((n) => districtFilter == 'all' || n.project.districtId == districtFilter)
        .where((n) => typeFilter == 'all' || typeFilter == 'funding')
        .toList();
    final filteredProjects = openProjects
        .where((p) => districtFilter == 'all' || p.districtId == districtFilter)
        .where((p) => typeFilter == 'all' || typeFilter == 'funding')
        .toList();

    void openBrief(Project project) {
      final issue = store.masterIssues.where((mi) => mi.id == project.issueId).toList();
      final owner = store.institutions.where((i) => i.id == project.ownerId).toList();
      final district = districts.where((d) => d.id == project.districtId).toList();
      ProjectBriefModal.show(
        context,
        project: project,
        issue: issue.isNotEmpty ? issue.first : null,
        owner: owner.isNotEmpty ? owner.first : null,
        district: district.isNotEmpty ? district.first : null,
        partner: partner,
        onSupportMilestone: (milestoneId, budget, title) {
          Navigator.of(context).pop();
          _pledge(
            project,
            partner,
            Pledge(
              id: '',
              partnerId: partner.id,
              type: 'funding',
              amount: budget,
              description: t('opportunities.fundingForMilestone', {'title': title}),
              scope: 'milestone',
              milestoneId: milestoneId,
              status: 'pledged',
            ),
          );
        },
        onSupportProject: () {
          Navigator.of(context).pop();
          _pledge(
            project,
            partner,
            Pledge(
              id: '',
              partnerId: partner.id,
              type: 'funding',
              amount: (project.budget * 0.2).round().toDouble(),
              description: t('opportunities.projectLevelFunding'),
              scope: 'project',
              status: 'pledged',
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: GovPageHeader(title: t('opportunities.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('opportunities.viewingAs', {'name': partner.name}),
              style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatTile(
                      value: '${needsFromMilestones.length + openProjects.length}', label: t('opportunities.openOpportunities'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: formatCurrency(totalNeeded), label: t('opportunities.fundingStillNeeded'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$strongMatches', label: t('opportunities.strongMatches'))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: districtFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t('common.allDistricts'))),
                    for (final d in districts) DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => districtFilter = v ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: typeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t('opportunities.allTypes'))),
                    for (final ty in _pledgeTypes) DropdownMenuItem(value: ty, child: Text(t('opportunities.typeLabels.$ty'))),
                  ],
                  onChanged: (v) => setState(() => typeFilter = v ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(t('opportunities.projectMilestoneNeeds'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final n in filteredNeeds) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text('${n.project.title} — ${n.milestone.title}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              AIBadge(label: t('opportunities.matchPct', {'pct': '${(relevanceFor(n.project).score * 100).round()}'})),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${formatCurrency(n.milestone.budget)} ${t('opportunities.needed')}',
                              style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CivixButton(
                          label: t('opportunities.viewProjectBrief'),
                          variant: CivixButtonVariant.secondary,
                          size: CivixButtonSize.sm,
                          onPressed: () => openBrief(n.project),
                        ),
                        const SizedBox(height: 6),
                        CivixButton(
                          label: t('opportunities.supportThisMilestone'),
                          size: CivixButtonSize.sm,
                          onPressed: () => _pledge(
                            n.project,
                            partner,
                            Pledge(
                              id: '',
                              partnerId: partner.id,
                              type: 'funding',
                              amount: n.milestone.budget,
                              description: t('opportunities.fundingForMilestone', {'title': n.milestone.title}),
                              scope: 'milestone',
                              milestoneId: n.milestone.id,
                              status: 'pledged',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (filteredNeeds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t('opportunities.noOpenGaps'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
            ),

          if (typeFilter == 'all' || typeFilter == 'equipment') ...[
            const SizedBox(height: 20),
            Text(t('opportunities.capabilityGaps'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final g in gaps) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  child: Row(
                    children: [
                      Expanded(child: Text(g.label, style: const TextStyle(fontSize: 13))),
                      CivixButton(
                        label: g.kind == 'expert'
                            ? t('opportunities.offerExpert')
                            : g.kind == 'lab'
                                ? t('opportunities.offerLabAccess')
                                : g.kind == 'capacity'
                                    ? t('opportunities.offerCapacitySupport')
                                    : t('opportunities.offerEquipment'),
                        variant: CivixButtonVariant.secondary,
                        size: CivixButtonSize.sm,
                        onPressed: () => ref.read(civixStoreProvider.notifier).fillCapabilityGap(g.id, partner.name, partner.name),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (gaps.isEmpty)
              Text(t('opportunities.noOpenGaps'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          ],

          const SizedBox(height: 20),
          Text(t('opportunities.supportFullProject'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in filteredProjects) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(p.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              AIBadge(label: t('opportunities.matchToProfile', {'pct': '${(relevanceFor(p).score * 100).round()}'})),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(relevanceFor(p).reasons.first, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CivixButton(
                          label: t('opportunities.viewProjectBrief'),
                          variant: CivixButtonVariant.secondary,
                          size: CivixButtonSize.sm,
                          onPressed: () => openBrief(p),
                        ),
                        const SizedBox(height: 6),
                        CivixButton(
                          label: t('opportunities.supportTheFullProject'),
                          size: CivixButtonSize.sm,
                          onPressed: () => _pledge(
                            p,
                            partner,
                            Pledge(
                              id: '',
                              partnerId: partner.id,
                              type: 'funding',
                              amount: (p.budget * 0.2).round().toDouble(),
                              description: t('opportunities.projectLevelFunding'),
                              scope: 'project',
                              status: 'pledged',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CivixColors.neel)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ],
      ),
    );
  }
}
