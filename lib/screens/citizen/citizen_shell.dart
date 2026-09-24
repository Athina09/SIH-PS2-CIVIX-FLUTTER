import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CitizenShell extends StatelessWidget {
  final Widget child;
  const CitizenShell({super.key, required this.child});

  int _indexFor(String location) {
    if (location.startsWith('/citizen/report')) return 1;
    if (location.startsWith('/citizen/wall')) return 2;
    if (location.startsWith('/citizen/my-reports')) return 3;
    if (location.startsWith('/citizen/channels')) return 4;
    if (location.startsWith('/citizen/scan')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Wall'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Mine'),
          NavigationDestination(icon: Icon(Icons.share_outlined), selectedIcon: Icon(Icons.share), label: 'Channels'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/citizen'); break;
            case 1: context.go('/citizen/report'); break;
            case 2: context.go('/citizen/wall'); break;
            case 3: context.go('/citizen/my-reports'); break;
            case 4: context.go('/citizen/channels'); break;
            case 5: context.go('/citizen/scan'); break;
          }
        },
      ),
    );
  }
}
