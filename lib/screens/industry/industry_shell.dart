import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IndustryShell extends StatelessWidget {
  final Widget child;
  const IndustryShell({super.key, required this.child});

  static const _items = [
    ('/industry/opportunities', 'Opportunities', Icons.dashboard_outlined),
    ('/industry/portfolio', 'Portfolio', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Industry')),
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
