// Ported from src/features/citizen/VillageWall.tsx
// The map view (IssueMap.tsx, Leaflet-based) has no port here yet — this screen always renders
// the list view, same as the React app does automatically whenever Data saver mode is on.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/districts.dart' as district_data;
import '../../engines/priority.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/merged_badge.dart';
import '../../widgets/panel.dart';
import '../../widgets/status_chip.dart';

const Map<String, ChipTone> _stageTone = {
  'awaiting-validation': ChipTone.neutral,
  'validated': ChipTone.progress,
  'routed-service': ChipTone.progress,
  'routed-innovation': ChipTone.progress,
  'in-project': ChipTone.progress,
  'resolved': ChipTone.success,
  'closed-failed': ChipTone.risk,
};

class VillageWallScreen extends ConsumerStatefulWidget {
  const VillageWallScreen({super.key});

  @override
  ConsumerState<VillageWallScreen> createState() => _VillageWallScreenState();
}

class _VillageWallScreenState extends ConsumerState<VillageWallScreen> {
  String district = 'all';
  String category = 'all';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final ranked = store.masterIssues
        .where((mi) => district == 'all' || mi.districtId == district)
        .where((mi) => category == 'all' || mi.category == category)
        .map((mi) => (
              mi: mi,
              priority: computePriority(
                category: mi.category,
                households: mi.households,
                upvotes: mi.upvotes,
                districtId: mi.districtId,
                districts: store.districts,
                season: store.season,
                rainfallAnomalyPct: store.rainfallAnomalyPct,
                drought: store.drought,
              ).total,
            ))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final promotedSystemic = store.systemicChallenges.where((sc) => sc.promoted).toList();

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('villageWall.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          for (final sc in promotedSystemic)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${t('villageWall.sameRootCause')} ${sc.districtIds.length} ${t('villageWall.districts')}',
                        style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: district,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t('common.allDistricts'))),
                    ...district_data.districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => district = v ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t('categories.all'))),
                    ...kCategories.map((c) => DropdownMenuItem(value: c, child: Text(t('categories.$c'), overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => category = v ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in ranked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => context.go('/citizen/wall/${r.mi.id}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(r.mi.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                MergedBadge(count: r.mi.reportIds.length),
                              ],
                            ),
                          ),
                          StatusChip(label: r.mi.stage.replaceAll('-', ' '), tone: _stageTone[r.mi.stage] ?? ChipTone.neutral),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${r.mi.village} · ${t('villageWall.priority')} ${r.priority.round()} · ${r.mi.reportIds.length} ${t('villageWall.reportsTotal')}',
                          style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${r.mi.households} ${t('villageWall.households')}', style: const TextStyle(fontSize: 12)),
                          OutlinedButton(
                            onPressed: () => notifier.upvoteIssue(r.mi.id, persona.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: CivixColors.rule),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text('▲ ${r.mi.upvotes}', style: const TextStyle(fontSize: 12, color: CivixColors.neel)),
                          ),
                        ],
                      ),
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
