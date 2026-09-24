// Ported from src/features/citizen/ChannelSimulators.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';
import '../../widgets/social_signal_feed.dart';

class ChannelSimulatorsScreen extends ConsumerWidget {
  const ChannelSimulatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('channels.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Panel(child: SocialSignalFeed(interactive: true)),
        ],
      ),
    );
  }
}
