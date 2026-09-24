// Ported from src/features/government/AuditLog.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/gov_page_header.dart';
import '../../widgets/panel.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);

    final filtered = store.auditLog.where((a) {
      final haystack = '${a.actor} ${a.action} ${a.target} ${a.detail ?? ''}'.toLowerCase();
      return haystack.contains(filter.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: GovPageHeader(title: t('auditLog.heading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              decoration: InputDecoration(hintText: t('auditLog.filterPlaceholder'), border: const OutlineInputBorder(), isDense: true),
              onChanged: (v) => setState(() => filter = v),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              children: [
                for (final a in filtered)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CivixColors.rule))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: CivixColors.neel),
                            children: [
                              TextSpan(text: a.action),
                              TextSpan(text: ' — ${a.target}', style: const TextStyle(color: CivixColors.neelSoft)),
                            ],
                          ),
                        ),
                        if (a.detail != null) Text(a.detail!, style: const TextStyle(fontSize: 11, color: CivixColors.ember)),
                        Text('${a.actor} (${a.role}) · ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(a.at))}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
