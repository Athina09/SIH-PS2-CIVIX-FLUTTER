// Ported from src/components/signature/ThreadGlyph.tsx
// Nine 4px dots, filled up to the current stage. The app's mark of progress — used in every
// row, list item and notification.
import 'package:flutter/material.dart';
import '../../engines/chain.dart';
import '../../theme/theme.dart';

class ThreadGlyph extends StatelessWidget {
  final int currentStep;
  const ThreadGlyph({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final role = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Stage ${currentStep + 1} of ${lifecycleSteps.length}: ${lifecycleSteps[currentStep]}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(lifecycleSteps.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= currentStep ? role : CivixColors.rule,
              ),
            ),
          );
        }),
      ),
    );
  }
}
