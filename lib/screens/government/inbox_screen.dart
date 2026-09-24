// Ported from src/features/government/Inbox.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engines/priority.dart';
import '../../engines/similarity.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/ai_badge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/merged_badge.dart';
import '../../widgets/panel.dart';

const _channelIcon = {'app': '📱', 'web': '🌐', 'social': '📣'};

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String tab = 'new';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);

    final newCases = store.masterIssues.where((mi) => mi.stage == 'awaiting-validation').toList();

    final rows = newCases.map((mi) {
      final priority = computePriority(
        category: mi.category,
        households: mi.households,
        upvotes: mi.upvotes,
        districtId: mi.districtId,
        districts: store.districts,
        season: store.season,
        rainfallAnomalyPct: store.rainfallAnomalyPct,
        drought: store.drought,
      ).total;
      final report = store.reports.where((r) => mi.reportIds.contains(r.id)).firstOrNull;
      final others = newCases.where((o) => o.id != mi.id).toList();
      final dup = findBestMatch(category: mi.category, lat: mi.lat, lng: mi.lng, createdAt: mi.createdAt, issues: others);
      final evidenceCount = store.reports.where((r) => r.masterIssueId == mi.id).fold<int>(0, (n, r) => n + r.evidence.length);
      final missing = [
        if (mi.village.isEmpty || RegExp(r'^unnamed', caseSensitive: false).hasMatch(mi.village)) 'village',
        if (mi.households == 0) 'household count',
        if (evidenceCount == 0) 'evidence',
      ];
      return (mi: mi, priority: priority, channel: report?.channel ?? 'app', isDup: dup?.result.isDuplicate ?? false, evidenceCount: evidenceCount, missing: missing);
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final needsInfo = rows.where((r) => r.missing.isNotEmpty).toList();

    return Scaffold(
      appBar: GovPageHeader(title: t('inbox.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _TabChip(label: t('inbox.tabs.new'), selected: tab == 'new', onTap: () => setState(() => tab = 'new')),
              const SizedBox(width: 8),
              _TabChip(label: t('inbox.tabs.social'), selected: tab == 'social', onTap: () => setState(() => tab = 'social')),
              const SizedBox(width: 8),
              _TabChip(label: t('inbox.tabs.info'), selected: tab == 'info', onTap: () => setState(() => tab = 'info')),
            ],
          ),
          const SizedBox(height: 16),

          if (tab == 'new')
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AIBadge(label: t('inbox.aiAnalysed', {'count': '${rows.length}'})),
                  const SizedBox(height: 12),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(t('inbox.noNewCases'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    )
                  else
                    for (final r in rows)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CivixColors.ruleHairline))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_channelIcon[r.channel] ?? '📱', style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Text(r.mi.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      MergedBadge(count: r.mi.reportIds.length),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.isDup ? t('inbox.likely') : '—'} · ${t('inbox.columns.priority')}: ${r.priority.round()} · ${t('inbox.columns.evidence')}: ${r.evidenceCount}',
                                    style: TextStyle(fontSize: 11, color: r.isDup ? CivixColors.ember : CivixColors.neelSoft),
                                  ),
                                ],
                              ),
                            ),
                            CivixButton(
                              label: t('inbox.openWorkbench'),
                              variant: CivixButtonVariant.secondary,
                              size: CivixButtonSize.sm,
                              onPressed: () => context.go('/gov/issues/${r.mi.id}'),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),

          if (tab == 'social') const _SocialSignalPanel(),

          if (tab == 'info')
            Column(
              children: [
                for (final r in needsInfo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Panel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.mi.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${t('inbox.missing')}: ${r.missing.join(', ')}', style: const TextStyle(fontSize: 11, color: CivixColors.ember)),
                              ],
                            ),
                          ),
                          CivixButton(
                            label: t('inbox.openWorkbench'),
                            variant: CivixButtonVariant.secondary,
                              size: CivixButtonSize.sm,
                            onPressed: () => context.go('/gov/issues/${r.mi.id}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (needsInfo.isEmpty) Panel(child: Text(t('inbox.allInfoComplete'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))),
              ],
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _SocialSignalPanel extends ConsumerWidget {
  const _SocialSignalPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final persona = ref.watch(personaProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final posts = store.socialPosts;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in posts)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: CivixColors.ruleHairline), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.platform, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CivixColors.neelSoft)),
                            const SizedBox(width: 4),
                            Text('· ${p.author}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                            if (p.verified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, size: 12, color: CivixColors.kusum)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p.text, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (p.converted ?? false)
                    const Icon(Icons.check_circle, color: CivixColors.sal, size: 20)
                  else
                    CivixButton(
                      label: 'Convert',
                      variant: CivixButtonVariant.secondary,
                              size: CivixButtonSize.sm,
                      onPressed: () => notifier.convertSocialSignal(p.id, persona.name),
                    ),
                ],
              ),
            ),
          if (posts.isEmpty) Text(t('inbox.noNewCases'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
