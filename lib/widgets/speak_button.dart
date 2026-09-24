// Ported from src/components/ui/SpeakButton.tsx + hooks/useSpeak.ts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../state/a11y_store.dart';

final _ttsProvider = Provider<FlutterTts>((ref) => FlutterTts());

class SpeakButton extends ConsumerWidget {
  final String text;
  const SpeakButton({super.key, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readAloud = ref.watch(a11yStoreProvider.select((s) => s.readAloud));
    if (!readAloud) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.volume_up_outlined, size: 18),
      tooltip: 'Read this aloud',
      onPressed: () => ref.read(_ttsProvider).speak(text),
    );
  }
}
