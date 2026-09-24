// Ported from src/features/industry/IndustryPortfolio.tsx
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

const _pledgeTypes = ['funding', 'mentoring', 'equipment', 'manufacturing', 'testing'];

Color _typeColor(BuildContext context, String type) {
  switch (type) {
    case 'funding':
      return Theme.of(context).colorScheme.primary;
    case 'mentoring':
      return CivixColors.sal;
    case 'equipment':
      return CivixColors.tasar;
    case 'manufacturing':
      return CivixColors.kusum;
    case 'testing':
      return CivixColors.lac;
    default:
      return CivixColors.neel;
  }
}

class IndustryPortfolioScreen extends ConsumerWidget {
  const IndustryPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final partnerMatches = store.partners.where((p) => p.id == persona.partnerId).toList();
    final partner = partnerMatches.isNotEmpty ? partnerMatches.first : store.partners.first;

    final myPledges = <({Project project, Pledge pledge})>[];
    for (final p in store.projects) {
      for (final pl in p.pledges) {
        if (pl.partnerId == partner.id) myPledges.add((project: p, pledge: pl));
      }
    }
    final beneficiaries = store.projects.fold<int>(0, (s, p) => s + p.qrFeedback.where((f) => f.outcome == 'works').length);

    final totalPledged = myPledges.fold<double>(0, (s, e) => s + (e.pledge.amount ?? 0));
    final totalReleased = myPledges
        .where((e) => e.pledge.status == 'released')
        .fold<double>(0, (s, e) => s + (e.pledge.amount ?? 0));
    final releasedPct = totalPledged > 0 ? (totalReleased / totalPledged * 100).round() : 0;

    final byType = [
      for (final type in _pledgeTypes) (type: type, count: myPledges.where((e) => e.pledge.type == type).length),
    ];
    final maxTypeCount = math.max(1, byType.fold<int>(0, (m, bt) => math.max(m, bt.count)));

    return Scaffold(
      appBar: GovPageHeader(title: t('industryPortfolio.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(partner.name, style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(value: '${myPledges.length}', label: t('industryPortfolio.pledgesMade'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: formatCurrency(totalPledged), label: t('industryPortfolio.totalPledged'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$beneficiaries', label: t('industryPortfolio.qrConfirmedBeneficiaries'))),
            ],
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('industryPortfolio.fundsReleasedVsPledged'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${formatCurrency(totalReleased)} ${t('industryPortfolio.released')}',
                        style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    Text('${formatCurrency(totalPledged)} ${t('industryPortfolio.pledged')}',
                        style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: releasedPct / 100,
                    minHeight: 10,
                    backgroundColor: CivixColors.chuna,
                    valueColor: const AlwaysStoppedAnimation(CivixColors.lac),
                  ),
                ),
                const SizedBox(height: 4),
                Text(t('industryPortfolio.releasedPctOfMilestones', {'pct': '$releasedPct'}),
                    style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('industryPortfolio.supportByType'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                if (byType.every((bt) => bt.count == 0))
                  Text(t('industryPortfolio.noPledgesYet'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft))
                else
                  for (final bt in byType.where((bt) => bt.count > 0)) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 90, child: Text(t('opportunities.typeLabels.${bt.type}'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: bt.count / maxTypeCount,
                                minHeight: 8,
                                backgroundColor: CivixColors.chuna,
                                valueColor: AlwaysStoppedAnimation(_typeColor(context, bt.type)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 20, child: Text('${bt.count}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(t('industryPortfolio.pledgeRecord'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in myPledges) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.project.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '${e.pledge.description}${e.pledge.amount != null ? ' · ${formatCurrency(e.pledge.amount!)}' : ''}',
                            style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (e.pledge.status == 'released' ? CivixColors.lac : CivixColors.tasar).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t('industryPortfolio.pledgeStatus.${e.pledge.status}'),
                        style: TextStyle(fontSize: 11, color: e.pledge.status == 'released' ? CivixColors.lac : CivixColors.tasar),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (myPledges.isEmpty)
            Text(t('industryPortfolio.noPledgesVisitOpportunities'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('industryPortfolio.csrImpactReport'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: CivixColors.neel),
                    children: [
                      TextSpan(text: '${t('industryPortfolio.qrConfirmedAcrossProjects')} '),
                      TextSpan(text: '$beneficiaries', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CivixButton(
                  label: t('industryPortfolio.printReport'),
                  variant: CivixButtonVariant.secondary,
                  size: CivixButtonSize.sm,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('industryPortfolio.printReport'))),
                  ),
                ),
              ],
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
