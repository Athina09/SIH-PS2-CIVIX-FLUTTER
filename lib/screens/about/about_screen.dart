// Ported from src/features/about/About.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/dictionary.dart';
import '../../theme/theme.dart';
import '../../widgets/panel.dart';

const List<Map<String, bool>> _competitiveFlags = [
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': true, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
  {'cpgrams': false, 'fixmystreet': false, 'projectPortal': false, 'civix': true},
];

const List<String> _references = [
  'Pak, B., Chua, A., & Vande Moere, A. (2017). FixMyStreet Brussels: Socio-demographic inequality in crowdsourced civic participation. Journal of Urban Technology.',
  'NYC 311 service request dataset',
  'FixMyStreet Brussels API',
  'AI4Bharat IndicVoices',
  'Jharkhand District Census Handbooks',
];

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final features = t.list('about.features');
    final pyramidSteps = t.list('about.pyramidSteps');

    return Scaffold(
      appBar: AppBar(title: Text(t('appName'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t('about.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(t('about.intro'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft, height: 1.5)),
          const SizedBox(height: 20),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('about.evidencePyramid'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (var i = 0; i < pyramidSteps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${i + 1}. ${pyramidSteps[i]}', style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('about.competitiveLandscape'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(t('about.columns.capability'))),
                      DataColumn(label: Text(t('about.columns.cpgrams'))),
                      DataColumn(label: Text(t('about.columns.fixmystreet'))),
                      DataColumn(label: Text(t('about.columns.projectPortal'))),
                      DataColumn(label: Text(t('about.columns.civix'))),
                    ],
                    rows: [
                      for (var i = 0; i < features.length && i < _competitiveFlags.length; i++)
                        DataRow(cells: [
                          DataCell(Text(features[i], style: const TextStyle(fontSize: 12))),
                          DataCell(_Check(v: _competitiveFlags[i]['cpgrams']!)),
                          DataCell(_Check(v: _competitiveFlags[i]['fixmystreet']!)),
                          DataCell(_Check(v: _competitiveFlags[i]['projectPortal']!)),
                          DataCell(_Check(v: _competitiveFlags[i]['civix']!)),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('about.referencesAndDatasets'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (final r in _references)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('•  $r', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool v;
  const _Check({required this.v});

  @override
  Widget build(BuildContext context) {
    return Text(v ? '✓' : '—', style: TextStyle(color: v ? CivixColors.lac : CivixColors.neelSoft.withValues(alpha: 0.4), fontWeight: FontWeight.bold));
  }
}
