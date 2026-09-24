import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'state/civix_store.dart';
import 'theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: CivixApp()));
}

class CivixApp extends ConsumerWidget {
  const CivixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final session = ref.watch(civixStoreProvider).session;
    return MaterialApp.router(
      title: 'CIVIX',
      debugShowCheckedModeBanner: false,
      theme: civixTheme(role: session.role),
      routerConfig: router,
    );
  }
}
