// Ported from src/features/government/ServiceTwinBoard.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/routing.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/department_seal.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/merged_badge.dart';
import '../../widgets/panel.dart';

const _columns = ['assigned', 'in-progress', 'resolved'];

class ServiceTwinBoardScreen extends ConsumerWidget {
  const ServiceTwinBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final allDepartments = departmentByCategory.values.map((d) => d.department).toSet().toList();
    final withTickets = store.masterIssues.where((mi) => mi.serviceTicket != null).toList();
    final byDept = <String, List<MasterIssue>>{};
    for (final mi in withTickets) {
      byDept.putIfAbsent(mi.serviceTicket!.department, () => []).add(mi);
    }

    return Scaffold(
      appBar: GovPageHeader(title: t('serviceTwinBoard.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final dept in allDepartments)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(14), color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DepartmentSeal(department: dept, size: 36),
                      const SizedBox(width: 8),
                      Text(dept, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: CivixColors.chuna, borderRadius: BorderRadius.circular(999)),
                        child: Text(t('serviceTwinBoard.caseCount', {'count': '${(byDept[dept] ?? []).length}'}), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if ((byDept[dept] ?? []).isEmpty)
                    Text(t('serviceTwinBoard.noOpenTickets'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft))
                  else
                    for (final col in _columns) ...[
                      Text(t('serviceTwinBoard.columns.$col').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CivixColors.neelSoft)),
                      const SizedBox(height: 6),
                      for (final i in byDept[dept]!.where((i) => i.serviceTicket!.status == col))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(i.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    MergedBadge(count: i.reportIds.length),
                                  ],
                                ),
                                Text(t('serviceTwinBoard.slaDays', {'days': '${i.serviceTicket!.slaDays}'}), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (col != 'resolved')
                                      CivixButton(
                                        label: t('serviceTwinBoard.resolve'),
                                        variant: CivixButtonVariant.secondary,
                                        size: CivixButtonSize.sm,
                                        onPressed: () => notifier.resolveServiceTicket(i.id, persona.name),
                                      ),
                                    if (i.repeatCount >= 2)
                                      CivixButton(
                                        label: t('serviceTwinBoard.escalateToInnovation'),
                                        size: CivixButtonSize.sm,
                                        onPressed: () => notifier.escalateToInnovation(i.id, persona.name),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (byDept[dept]!.where((i) => i.serviceTicket!.status == col).isEmpty)
                        const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('—', style: TextStyle(fontSize: 11, color: CivixColors.rule))),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
