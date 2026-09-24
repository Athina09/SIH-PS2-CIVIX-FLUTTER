// Ported from src/features/project/PublicProjectPage.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/panel.dart';

const _outcomeIds = ['works', 'partial', 'not-working', 'needs-maintenance'];

class PublicProjectScreen extends ConsumerStatefulWidget {
  final String projectId;
  const PublicProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<PublicProjectScreen> createState() => _PublicProjectScreenState();
}

class _PublicProjectScreenState extends ConsumerState<PublicProjectScreen> {
  bool _submitted = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final project = store.projects.where((p) => p.id == widget.projectId).firstOrNull;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('publicProjectPage.notFound'))),
        body: Center(child: Text(t('publicProjectPage.notFound'))),
      );
    }

    final owner = store.institutions.where((i) => i.id == project.ownerId).firstOrNull;
    final totalSpent = project.milestones.where((m) => m.status == 'released').fold<double>(0, (s, m) => s + m.budget);

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(t('publicProjectPage.builtBy'), owner?.name ?? ''),
                const SizedBox(height: 6),
                _kv(t('publicProjectPage.fundsUsed'), '${formatCurrency(totalSpent)} ${t('liveProjectRecord.of')} ${formatCurrency(project.budget)}'),
                const SizedBox(height: 6),
                _kv(t('publicProjectPage.status'), project.stage.replaceAll('-', ' ')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('publicProjectPage.whatWasFixed'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(project.maintenancePlan, style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!_submitted)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('publicProjectPage.howIsThisWorking'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                    children: [
                      for (final id in _outcomeIds)
                        CivixButton(
                          label: t('publicProjectPage.outcomes.$id'),
                          variant: CivixButtonVariant.secondary,
                          onPressed: () {
                            ref.read(civixStoreProvider.notifier).submitQRFeedback(
                                  project.id,
                                  outcome: id,
                                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                                );
                            setState(() => _submitted = true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: t('publicProjectPage.optionalNote'),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            )
          else
            Panel(
              child: Center(
                child: Text(t('publicProjectPage.thankYou'), style: const TextStyle(color: CivixColors.lac)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: CivixColors.neel),
          children: [
            TextSpan(text: '$k ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: v),
          ],
        ),
      );
}
