// Ported from src/features/government/CapabilityGaps.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

class CapabilityGapsScreen extends ConsumerWidget {
  const CapabilityGapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    return Scaffold(
      appBar: GovPageHeader(title: t('capabilityGaps.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in store.capabilityGaps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${g.kind} · ${g.districtIds.map((id) => store.districts.where((d) => d.id == id).firstOrNull?.name ?? '').join(', ')}',
                            style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                          ),
                        ],
                      ),
                    ),
                    if (g.filledBy != null)
                      Text('${t('capabilityGaps.filledBy')} ${g.filledBy}', style: const TextStyle(fontSize: 11, color: CivixColors.lac))
                    else if (g.published)
                      Text(t('capabilityGaps.published'), style: const TextStyle(fontSize: 11, color: CivixColors.tasar))
                    else
                      CivixButton(
                        label: t('capabilityGaps.publishToIndustry'),
                        size: CivixButtonSize.sm,
                        onPressed: () => notifier.publishCapabilityGap(g.id, persona.name),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
