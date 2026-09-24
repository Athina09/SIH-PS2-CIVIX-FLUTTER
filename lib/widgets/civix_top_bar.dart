// Ported from src/components/layout/TopBar.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../i18n/dictionary.dart';
import '../state/civix_store.dart';
import '../state/session.dart';
import '../theme/theme.dart';

const List<String> _roleOrder = ['citizen', 'government', 'university', 'industry', 'council'];

class CivixTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const CivixTopBar({super.key, this.title = 'CIVIX'});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final session = store.session;
    final unread = store.notifications.where((n) => (n.toRole == session.role || n.toRole == 'all') && !n.read).length;
    final role = Theme.of(context).colorScheme.primary;
    final t = ref.watch(dictionaryProvider);

    return AppBar(
      title: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: role),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              session.profile != null ? '${session.profile!.name} · ${t('roles.${session.role}')}' : 'Viewing as: ${t('roles.${session.role}')}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Switch role',
          onSelected: (r) => context.go('/login/$r'),
          itemBuilder: (context) => _roleOrder.map((r) => PopupMenuItem(value: r, child: Text(t('roles.$r')))).toList(),
        ),
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: 'Toggle language',
          onPressed: () => notifier.setLang(session.lang == AppLang.en ? AppLang.hi : AppLang.en),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.go('/notifications')),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: CivixColors.ember, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
        if (session.profile != null)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              notifier.logout();
              context.go('/');
            },
          ),
      ],
    );
  }
}
