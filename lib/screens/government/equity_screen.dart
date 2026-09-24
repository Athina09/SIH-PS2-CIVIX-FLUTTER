// Ported from src/features/government/Equity.tsx
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/equity.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final a = sinDLat * sinDLat + math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * sinDLng * sinDLng;
  return r * 2 * math.asin(math.sqrt(a));
}

class EquityScreen extends ConsumerWidget {
  const EquityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final results = computeEquity(store.districts);
    final flagged = results.where((r) => r.flagged).toList();

    Institution nearestHEI(String districtId) {
      final d = store.districts.firstWhere((x) => x.id == districtId);
      final sorted = [...store.institutions]..sort((a, b) => _haversine(d.lat, d.lng, a.lat, a.lng).compareTo(_haversine(d.lat, d.lng, b.lat, b.lng)));
      return sorted.first;
    }

    final sortedResults = [...results]..sort((a, b) => b.equityGap.compareTo(a.equityGap));

    return Scaffold(
      appBar: GovPageHeader(title: t('equity.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: SizedBox(
              height: 260,
              child: ScatterChart(
                ScatterChartData(
                  minX: 0,
                  maxX: 1,
                  minY: 0,
                  maxY: 1,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  scatterSpots: [
                    for (final r in results)
                      ScatterSpot(
                        r.reportRatePercentile,
                        r.needPercentile,
                        dotPainter: FlDotCirclePainter(radius: 6, color: const Color(0xFFE9761B)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('x: ${t('equity.reportRatePercentile')}  ·  y: ${t('equity.needPercentile')}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
          const SizedBox(height: 16),

          Panel(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t('equity.columns.district'))),
                  DataColumn(label: Text(t('equity.columns.need'))),
                  DataColumn(label: Text(t('equity.columns.reportRate'))),
                  DataColumn(label: Text(t('equity.columns.equityGap'))),
                  const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final r in sortedResults)
                    DataRow(
                      color: r.flagged ? WidgetStateProperty.all(CivixColors.ember.withValues(alpha: 0.05)) : null,
                      cells: [
                        DataCell(Text(store.districts.firstWhere((x) => x.id == r.districtId).name)),
                        DataCell(Text('${store.districts.firstWhere((x) => x.id == r.districtId).needIndex}')),
                        DataCell(Text('${store.districts.firstWhere((x) => x.id == r.districtId).reportRate}')),
                        DataCell(Text(r.equityGap.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(_buildAction(t, notifier, persona.name, store, r, nearestHEI)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (flagged.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: CivixColors.ember, width: 4))),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('equity.flaggedDistricts'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      flagged.map((f) => store.districts.firstWhere((d) => d.id == f.districtId).name).join(', '),
                      style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
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

  Widget _buildAction(
    AppDictionary t,
    CivixNotifier notifier,
    String actorName,
    CivixState store,
    EquityResult r,
    Institution Function(String) nearestHEI,
  ) {
    final task = store.outreachTasks.where((task) => task.districtId == r.districtId).firstOrNull;
    if (task == null && r.flagged) {
      return CivixButton(
        label: t('equity.triggerOutreach'),
        variant: CivixButtonVariant.secondary,
        size: CivixButtonSize.sm,
        onPressed: () => notifier.triggerOutreach(r.districtId, nearestHEI(r.districtId).id, actorName),
      );
    }
    if (task != null && task.status == 'assigned') {
      return CivixButton(
        label: t('equity.markCompleted'),
        size: CivixButtonSize.sm,
        onPressed: () => notifier.completeOutreach(task.id, actorName),
      );
    }
    if (task != null && task.status == 'completed') {
      return Text(t('equity.outreachCompleted'), style: const TextStyle(fontSize: 11, color: CivixColors.lac));
    }
    return const SizedBox.shrink();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
