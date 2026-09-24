// Ported from src/features/notifications/Notifications.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);

    final mine = store.notifications.where((n) => n.toRole == store.session.role || n.toRole == 'all').toList()
      ..sort((a, b) => DateTime.parse(b.at).compareTo(DateTime.parse(a.at)));

    final groups = <String, List<AppNotification>>{};
    final order = <String>[];
    for (final n in mine) {
      final day = DateFormat('d MMM yyyy').format(DateTime.parse(n.at));
      if (!groups.containsKey(day)) {
        groups[day] = [];
        order.add(day);
      }
      groups[day]!.add(n);
    }

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(t('notificationsPage.heading'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(t('notificationsPage.noneYet'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                ),
              for (final day in order) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 16),
                  child: Text(
                    day.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: CivixColors.neelSoft),
                  ),
                ),
                for (final n in groups[day]!) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(civixStoreProvider.notifier).markNotificationRead(n.id);
                        if (n.link != null) context.go(n.link!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CivixColors.page,
                          border: Border(
                            top: const BorderSide(color: CivixColors.rule),
                            right: const BorderSide(color: CivixColors.rule),
                            bottom: const BorderSide(color: CivixColors.rule),
                            left: BorderSide(color: n.read ? CivixColors.rule : roleColorOf(store.session.role), width: 4),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.text, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('h:mm a').format(DateTime.parse(n.at))}'
                              '${_isSameDay(DateTime.parse(n.at), now) ? ' · ${t('notificationsPage.today')}' : ''}',
                              style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
