// Ported from src/components/signature/CaseThread.tsx — mobile (vertical list) variant only,
// since this is a native mobile app; the wide desktop SVG thread has no natural phone-width
// equivalent and the source app itself falls back to this same list layout below `sm:`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engines/chain.dart';
import '../../state/civix_store.dart';
import '../../state/session.dart';
import '../../theme/theme.dart';

class CaseThread extends ConsumerWidget {
  final int currentStep;
  final void Function(int index)? onKnotClick;

  const CaseThread({super.key, required this.currentStep, this.onKnotClick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(civixStoreProvider.select((s) => s.session.lang));
    final labels = lang == AppLang.hi ? lifecycleStepsHi : lifecycleSteps;
    final role = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (i) {
        final isCurrent = i == currentStep;
        final isDone = i < currentStep;
        return InkWell(
          onTap: onKnotClick != null ? () => onKnotClick!(i) : null,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      if (isCurrent)
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: role, width: 2)),
                          child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: role)),
                        )
                      else
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? role : Colors.transparent,
                            border: Border.all(color: role.withValues(alpha: isDone ? 1 : 0.5)),
                          ),
                        ),
                      if (i < labels.length - 1)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: isDone ? role : role.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCurrent ? CivixColors.neel : CivixColors.neelSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
