// Ported from src/features/citizen/ScanQR.tsx
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/panel.dart';

const _deployedStages = {'deployed', 'community-validated', 'scaled'};

class ScanQRScreen extends ConsumerStatefulWidget {
  const ScanQRScreen({super.key});

  @override
  ConsumerState<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends ConsumerState<ScanQRScreen> {
  String? scanning;

  void _scanProject(String id) {
    setState(() => scanning = id);
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      context.go('/p/$id');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final role = Theme.of(context).colorScheme.primary;
    final deployed = store.projects.where((p) => _deployedStages.contains(p.stage)).toList();

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('scanQR.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: CivixColors.rule, width: 2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.qr_code_scanner, size: 40, color: scanning != null ? role : CivixColors.neelSoft.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 8),
                Text(t('scanQR.hint'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final p in deployed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                    CivixButton(label: t('scanQR.scan'), size: CivixButtonSize.sm, onPressed: () => _scanProject(p.id)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
