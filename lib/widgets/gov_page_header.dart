// Shared header for screens hosted inside a Drawer-based role shell (GovShell, UniShell,
// IndustryShell) that has no AppBar of its own — opens that ancestor Scaffold's drawer.
import 'package:flutter/material.dart';

class GovPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GovPageHeader({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(title),
      actions: actions,
    );
  }
}
