// Ported from src/features/knowledge/KnowledgeGraph.tsx
//
// The React version renders an interactive node graph (problem -> solution -> institution)
// via @xyflow/react. There's no graph-visualization package in this Flutter project's
// dependencies, so this port keeps the same data relationships and interactions (search,
// select an entry, see its detail panel, plus the flat list view) but presents the
// problem/solution/institution chain as a simple expandable list row instead of a canvas graph.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/panel.dart';

class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends ConsumerState<KnowledgeGraphScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final solutionMemory = store.solutionMemory;
    final institutions = store.institutions;

    final search = _searchController.text.trim().toLowerCase();
    final filtered = search.isEmpty
        ? solutionMemory
        : solutionMemory
            .where((s) => '${s.title} ${s.category} ${s.components.join(' ')}'.toLowerCase().contains(search))
            .toList();

    SolutionMemoryEntry? selectedEntry;
    for (final s in solutionMemory) {
      if (s.id == _selectedId) {
        selectedEntry = s;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('knowledgeGraph.heading'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: t('knowledgeGraph.searchPlaceholder'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Panel(
            child: selectedEntry == null
                ? Text(
                    t('knowledgeGraph.clickNodeForDetails'),
                    style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft),
                  )
                : _SelectedDetail(entry: selectedEntry),
          ),
          const SizedBox(height: 24),
          Text(t('knowledgeGraph.solutionMemoryListView'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final s in filtered) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedId = s.id),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(s.pilotResult, style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                      const SizedBox(height: 8),
                      _Chain(entry: s, institutions: institutions, t: t),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chain extends StatelessWidget {
  final SolutionMemoryEntry entry;
  final List<Institution> institutions;
  final AppDictionary t;
  const _Chain({required this.entry, required this.institutions, required this.t});

  @override
  Widget build(BuildContext context) {
    Institution? inst;
    for (final i in institutions) {
      if (i.id == entry.institutionId) {
        inst = i;
        break;
      }
    }
    final solutionLabel =
        '${t('knowledgeGraph.solutionPrefix')} ${entry.components.isNotEmpty ? entry.components.first : t('knowledgeGraph.componentsFallback')}';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        _NodeChip(label: entry.title, color: CivixColors.ember),
        const Icon(Icons.arrow_forward, size: 12, color: CivixColors.neelSoft),
        _NodeChip(label: solutionLabel, color: CivixColors.neel),
        const Icon(Icons.arrow_forward, size: 12, color: CivixColors.neelSoft),
        _NodeChip(label: inst?.name ?? entry.institutionId, color: CivixColors.kusum),
      ],
    );
  }
}

class _NodeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _NodeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _SelectedDetail extends ConsumerWidget {
  final SolutionMemoryEntry entry;
  const _SelectedDetail({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(entry.pilotResult, style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
        const SizedBox(height: 4),
        Text('${t('knowledgeGraph.cost')} ₹${_formatIndian(entry.cost)}', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text('${t('knowledgeGraph.lessons')} ${entry.lessons.join('; ')}', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

String _formatIndian(double value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  final len = s.length;
  for (var i = 0; i < len; i++) {
    final posFromEnd = len - i;
    buf.write(s[i]);
    if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
  }
  return buf.toString();
}
