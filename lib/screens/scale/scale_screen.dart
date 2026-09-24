// Ported from src/features/scale/Scale.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/replication.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/panel.dart';

const Map<String, Color> _verdictColor = {
  'REUSE': CivixColors.lac,
  'ADAPT': CivixColors.tasar,
  'NEW RESEARCH': CivixColors.ember,
};

class ScaleScreen extends ConsumerStatefulWidget {
  const ScaleScreen({super.key});

  @override
  ConsumerState<ScaleScreen> createState() => _ScaleScreenState();
}

class _ScaleScreenState extends ConsumerState<ScaleScreen> {
  String? _projectId;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final projects = store.projects;
    final districts = store.districts;

    final validated = projects.where((p) => p.stage == 'community-validated' || p.stage == 'scaled').toList();

    _projectId ??= (validated.isNotEmpty ? validated.first.id : (projects.isNotEmpty ? projects.first.id : null));

    Project? project;
    for (final p in projects) {
      if (p.id == _projectId) {
        project = p;
        break;
      }
    }
    District? sourceDistrict;
    if (project != null) {
      for (final d in districts) {
        if (d.id == project.districtId) {
          sourceDistrict = d;
          break;
        }
      }
    }

    final results = (project != null && sourceDistrict != null) ? replicationForProject(sourceDistrict, districts) : <ReplicationResult>[];

    return Scaffold(
      appBar: AppBar(title: Text(t('scale.heading'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (projects.isEmpty)
            const SizedBox.shrink()
          else
            DropdownButtonFormField<String>(
              initialValue: _projectId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: [
                for (final p in validated) DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis)),
                if (validated.isEmpty)
                  for (final p in projects)
                    DropdownMenuItem(value: p.id, child: Text('${p.title} ${t('scale.notYetValidated')}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: [
              for (final r in results)
                Builder(builder: (context) {
                  District? d;
                  for (final x in districts) {
                    if (x.id == r.districtId) {
                      d = x;
                      break;
                    }
                  }
                  final color = _verdictColor[r.verdict] ?? CivixColors.neel;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CivixColors.page,
                      border: Border(
                        top: const BorderSide(color: CivixColors.rule),
                        right: const BorderSide(color: CivixColors.rule),
                        bottom: const BorderSide(color: CivixColors.rule),
                        left: BorderSide(color: color, width: 4),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d?.name ?? r.districtId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(r.verdict, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                        const SizedBox(height: 4),
                        Text(r.rationale, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        if (r.adaptationNotes != null) ...[
                          const SizedBox(height: 4),
                          Text(r.adaptationNotes!, style: const TextStyle(fontSize: 11, color: CivixColors.tasar)),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('scale.pathToScale'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, s) in t.list('scale.stages').indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(999)),
                        child: Text('${i + 1}. $s', style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
