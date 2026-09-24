// Ported from src/features/landing/Login.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/dictionary.dart';
import '../../theme/theme.dart';
import '../../widgets/panel.dart';

const List<String> _roleOrder = ['citizen', 'government', 'university', 'industry', 'council'];

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('appName'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t('login.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(t('login.subheading'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          const SizedBox(height: 20),
          for (final role in _roleOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/login/$role'),
                child: Panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4, right: 10),
                        decoration: BoxDecoration(color: roleColorOf(role), shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('roles.$role'), style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                            const SizedBox(height: 4),
                            Text(t('login.blurbs.$role'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
