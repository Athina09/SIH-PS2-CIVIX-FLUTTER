import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GovShell extends StatelessWidget {
  final Widget child;
  const GovShell({super.key, required this.child});

  static const _items = [
    ('/gov', 'Control room', Icons.dashboard_outlined),
    ('/gov/inbox', 'Inbox', Icons.inbox_outlined),
    ('/gov/duplicates', 'Duplicates', Icons.merge_outlined),
    ('/gov/services', 'Services', Icons.build_outlined),
    ('/gov/systemic', 'Systemic', Icons.hub_outlined),
    ('/gov/equity', 'Equity', Icons.balance_outlined),
    ('/gov/projects', 'Projects', Icons.folder_outlined),
    ('/gov/capability-gaps', 'Capability gaps', Icons.warning_amber_outlined),
    ('/gov/audit', 'Audit log', Icons.receipt_long_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Government')),
            for (final item in _items)
              ListTile(
                title: Text(item.$2),
                leading: Icon(item.$3),
                selected: location == item.$1,
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}
