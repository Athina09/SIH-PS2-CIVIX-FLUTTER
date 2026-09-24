// Ported from src/features/government/SystemicChallenges.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

class SystemicChallengesScreen extends ConsumerWidget {
  const SystemicChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    return Scaffold(
      appBar: GovPageHeader(title: t('systemicChallenges.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final sc in store.systemicChallenges)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sc.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(sc.rootCause, style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                    const SizedBox(height: 4),
                    Text(
                      t('systemicChallenges.linkedIssues', {
                        'issues': '${store.masterIssues.where((mi) => sc.issueIds.contains(mi.id)).length}',
                        'districts': '${sc.districtIds.length}',
                      }),
                      style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                    ),
                    const SizedBox(height: 8),
                    if (sc.promoted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: CivixColors.kusum.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                        child: Text(t('systemicChallenges.promoted'), style: const TextStyle(fontSize: 11, color: CivixColors.kusum)),
                      )
                    else
                      CivixButton(
                        label: t('systemicChallenges.promoteToChallenge'),
                        size: CivixButtonSize.sm,
                        onPressed: () => notifier.promoteSystemic(sc.id, persona.name),
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
