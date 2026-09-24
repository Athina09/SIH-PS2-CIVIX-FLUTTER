// Ported from src/features/university/UniProfile.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';

class UniProfileScreen extends ConsumerWidget {
  const UniProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);

    final institutions = store.institutions;
    final instMatch = institutions.where((i) => i.id == persona.institutionId);
    final inst = instMatch.isNotEmpty ? instMatch.first : institutions.first;
    final history = inst.credibility.history;
    final recentHistory = history.length > 5 ? history.sublist(history.length - 5) : history;

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(inst.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('uniProfile.capabilities'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _kv(t('uniProfile.disciplines'), inst.disciplines.join(', ')),
                _kv(t('uniProfile.labs'), inst.labs.isEmpty ? t('uniProfile.noneListed') : inst.labs.join(', ')),
                _kv(t('uniProfile.equipment'), inst.equipment.isEmpty ? t('uniProfile.noneListed') : inst.equipment.join(', ')),
                _kv(t('uniProfile.availability'), '${inst.availability}%'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('uniProfile.credibility'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _Gauge(label: t('uniProfile.timeliness'), value: inst.credibility.timeliness),
                const SizedBox(height: 10),
                _Gauge(label: t('uniProfile.qrSuccess'), value: inst.credibility.qrSuccess),
                const SizedBox(height: 10),
                _Gauge(label: t('uniProfile.councilApproval'), value: inst.credibility.councilApproval),
                const SizedBox(height: 10),
                _Gauge(label: t('uniProfile.maintenance'), value: inst.credibility.maintenance),
                const SizedBox(height: 12),
                Text(
                  '${t('uniProfile.overall')} ${inst.credibility.overall.round()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (recentHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final h in recentHistory)
                    Text(
                      '${h.delta > 0 ? '+' : ''}${h.delta.toStringAsFixed(0)} — ${h.reason}',
                      style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13),
            children: [
              TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}

class _Gauge extends StatelessWidget {
  final String label;
  final double value;
  const _Gauge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: CivixColors.rule,
            valueColor: const AlwaysStoppedAnimation(CivixColors.sal),
          ),
        ),
      ],
    );
  }
}
