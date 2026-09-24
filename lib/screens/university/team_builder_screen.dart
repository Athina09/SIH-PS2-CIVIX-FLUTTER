// Ported from src/features/university/TeamBuilder.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../engines/capability_gap.dart';
import '../../engines/ranking.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';

class _MilestoneDraft {
  String title;
  double budget;
  String due;
  _MilestoneDraft({required this.title, required this.budget, required this.due});
}

class TeamBuilderScreen extends ConsumerStatefulWidget {
  final String issueId;
  const TeamBuilderScreen({super.key, required this.issueId});

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  String? selectedInst;
  final maintenancePlanController = TextEditingController();
  final titleController = TextEditingController();
  double budget = 400000;
  bool titleInitialized = false;
  late List<_MilestoneDraft> milestones;
  bool milestonesInitialized = false;

  String _dueInDays(int days) => DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: days)));

  @override
  void initState() {
    super.initState();
    milestones = [
      _MilestoneDraft(title: 'Design and site survey', budget: 100000, due: _dueInDays(30)),
      _MilestoneDraft(title: 'Build and installation', budget: 200000, due: _dueInDays(75)),
      _MilestoneDraft(title: 'Pilot, training and handover', budget: 100000, due: _dueInDays(120)),
    ];
  }

  @override
  void dispose() {
    maintenancePlanController.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final issueMatch = store.masterIssues.where((mi) => mi.id == widget.issueId);
    if (issueMatch.isEmpty) {
      return Scaffold(
        appBar: const CivixTopBar(),
        body: Center(child: Text(t('teamBuilder.notFound'))),
      );
    }
    final issue = issueMatch.first;

    if (!titleInitialized) {
      titleController.text = t('teamBuilder.innovationTwinTitle', {'title': issue.title});
      titleInitialized = true;
    }

    final disciplines = issue.problemStatement?.disciplinesNeeded ?? const <String>[];
    final ranked = topInstitutions(disciplines, issue.lat, issue.lng, store.institutions, n: 3);
    final chosen = ranked.isEmpty
        ? null
        : (ranked.where((r) => r.institution.id == selectedInst).isNotEmpty
            ? ranked.firstWhere((r) => r.institution.id == selectedInst)
            : ranked.first);
    final gaps = detectCapabilityGaps(disciplines, chosen != null ? [chosen.institution] : [], issue.category);

    final matchingGapList =
        store.capabilityGaps.where((g) => gaps.any((label) => g.label.toLowerCase().contains(label.toLowerCase())));
    final matchingGap = matchingGapList.isEmpty ? null : matchingGapList.first;

    final milestoneTotal = milestones.fold<double>(0, (sum, m) => sum + m.budget);
    final budgetsMatch = milestoneTotal == budget;
    final milestonesValid = milestones.isNotEmpty && milestones.every((m) => m.title.trim().isNotEmpty && m.budget > 0 && m.due.isNotEmpty);
    final inr = NumberFormat.decimalPattern('en_IN');

    void submit() {
      if (chosen == null || !budgetsMatch || !milestonesValid) return;
      final result = notifier.submitProposal(
        issueId: issue.id,
        institutionId: chosen.institution.id,
        memberIds: const ['Faculty lead', 'Student researcher'],
        disciplines: disciplines,
        title: titleController.text,
        budget: budget,
        milestones: milestones.map((m) => (title: m.title, budget: m.budget, due: m.due)).toList(),
        maintenancePlan: maintenancePlanController.text.trim().isNotEmpty
            ? maintenancePlanController.text.trim()
            : 'Institution provides quarterly maintenance checks for the first year.',
        actor: persona.name,
      );
      context.go('/projects/${result.projectId}');
    }

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('teamBuilder.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('${t('teamBuilder.for')} ${issue.title}', style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('teamBuilder.requiredDisciplines'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in disciplines)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(d, style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('teamBuilder.chooseLeadInstitution'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                for (final r in ranked)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: r.institution.id,
                    groupValue: selectedInst ?? ranked.first.institution.id,
                    onChanged: (v) => setState(() => selectedInst = v),
                    title: Text(r.institution.name, style: const TextStyle(fontSize: 13)),
                    secondary: Text('${t('teamBuilder.score')} ${(r.score * 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (gaps.isNotEmpty) ...[
            Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: CivixColors.ember, width: 4))),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t('teamBuilder.capabilityGapDetector')} ${gaps.join(', ')}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivixColors.ember),
                    ),
                    if (matchingGap != null && !matchingGap.published) ...[
                      const SizedBox(height: 8),
                      CivixButton(
                        label: t('teamBuilder.publishGapToIndustry'),
                        variant: CivixButtonVariant.secondary,
                        size: CivixButtonSize.sm,
                        onPressed: () => notifier.publishCapabilityGap(matchingGap.id, persona.name),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('teamBuilder.projectTitle'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Text(t('teamBuilder.totalBudget'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: budget.toStringAsFixed(0)),
                  onChanged: (v) => setState(() => budget = double.tryParse(v) ?? budget),
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('teamBuilder.milestones'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => setState(() => milestones.add(_MilestoneDraft(title: '', budget: 0, due: _dueInDays(30)))),
                      child: Text(t('teamBuilder.addMilestone'), style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                for (int i = 0; i < milestones.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: TextEditingController(text: milestones[i].title),
                            onChanged: (v) => milestones[i].title = v,
                            decoration: InputDecoration(isDense: true, border: const OutlineInputBorder(), hintText: t('teamBuilder.milestoneTitlePlaceholder')),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: milestones[i].budget.toStringAsFixed(0)),
                            onChanged: (v) => setState(() => milestones[i].budget = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: TextEditingController(text: milestones[i].due),
                            onChanged: (v) => milestones[i].due = v,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'yyyy-MM-dd'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: CivixColors.ember,
                          onPressed: milestones.length <= 1 ? null : () => setState(() => milestones.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${t('teamBuilder.milestonesTotal', {'total': inr.format(milestoneTotal), 'budget': inr.format(budget)})}'
                  '${budgetsMatch ? ' ✓' : ' ${t('teamBuilder.mustMatchBudget')}'}',
                  style: TextStyle(fontSize: 11, color: budgetsMatch ? CivixColors.lac : CivixColors.ember),
                ),
                const SizedBox(height: 12),
                Text(t('teamBuilder.maintenancePlan'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: maintenancePlanController,
                  maxLines: 2,
                  decoration: InputDecoration(isDense: true, border: const OutlineInputBorder(), hintText: t('teamBuilder.maintenancePlaceholder')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          CivixButton(
            label: t('teamBuilder.submitProposal'),
            onPressed: (budgetsMatch && milestonesValid && titleController.text.trim().isNotEmpty) ? submit : null,
          ),
        ],
      ),
    );
  }
}
