// Ported from src/features/landing/Landing.tsx (+ Hero.tsx). ReportMap.tsx's interactive map is
// summarised as a top-districts list here — a full Leaflet-style pan/zoom map has no natural
// mobile-first equivalent worth the extra dependency weight for a landing page.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/districts.dart';
import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/panel.dart';
import '../../widgets/signature/case_thread.dart';

const List<({String role, String to})> _workspaceRoles = [
  (role: 'citizen', to: '/citizen'),
  (role: 'government', to: '/gov'),
  (role: 'university', to: '/uni'),
  (role: 'industry', to: '/industry'),
  (role: 'council', to: '/council'),
];

const List<({String role, String to})> _pathwayRoles = [
  (role: 'government', to: '/gov'),
  (role: 'industry', to: '/industry'),
  (role: 'university', to: '/uni'),
];

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dictionaryProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final openIssues = store.masterIssues.where((i) => i.stage != 'closed-failed').length;
    final projectCount = store.projects.length;
    final districtsReached = store.projects.map((p) => p.districtId).toSet().length;

    void enterAs(String role) {
      notifier.setRole(role, guestPersona(role));
    }

    final reportsByDistrict = <String, int>{};
    for (final mi in store.masterIssues) {
      reportsByDistrict[mi.districtId] = (reportsByDistrict[mi.districtId] ?? 0) + 1;
    }
    final topDistricts = districts.toList()
      ..sort((a, b) => (reportsByDistrict[b.id] ?? 0).compareTo(reportsByDistrict[a.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(t('appName'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const _Hero(),
          const SizedBox(height: 28),

          Text(t('landing.whereReportsComingFrom'), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                for (final d in topDistricts.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d.name, style: const TextStyle(fontSize: 13)),
                        Text('${reportsByDistrict[d.id] ?? 0}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivixColors.neel)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const CaseThread(currentStep: 8),
          const SizedBox(height: 28),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              for (final w in _workspaceRoles)
                InkWell(
                  onTap: () {
                    enterAs(w.role);
                    context.go(w.to);
                  },
                  child: Panel(
                    child: Center(
                      child: Text(
                        t('landing.workspaces.${w.role}'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          Text(t('landing.waysToGetInvolved'), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          for (var i = 0; i < _pathwayRoles.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.raw('landing.pathways')[i]['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(t.raw('landing.pathways')[i]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                    const SizedBox(height: 4),
                    Text(t.raw('landing.pathways')[i]['description'] as String, style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CivixButton(
                        label: t.raw('landing.pathways')[i]['cta'] as String,
                        variant: CivixButtonVariant.secondary,
                        size: CivixButtonSize.sm,
                        onPressed: () {
                          enterAs(_pathwayRoles[i].role);
                          context.go(_pathwayRoles[i].to);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          Text(t('landing.builtForConnectedness'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in t.list('landing.features'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(999), color: Colors.white),
                  child: Text(f, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _StatTile(value: '$openIssues', label: t('landing.openIssues'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$projectCount', label: t('landing.projectsInMotion'))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$districtsReached', label: t('landing.districtsReached'))),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () => context.push('/about'),
              child: Text(t('landing.seeResearch'), style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CivixColors.neel)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ],
      ),
    );
  }
}

class _Hero extends ConsumerStatefulWidget {
  const _Hero();

  @override
  ConsumerState<_Hero> createState() => _HeroState();
}

class _HeroState extends ConsumerState<_Hero> {
  int _index = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext(int cycleLength) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _index = _index == cycleLength - 1 ? 0 : _index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final outcomes = t.list('hero.outcomes');
    if (outcomes.isNotEmpty) _scheduleNext(outcomes.length);

    return Column(
      children: [
        Text(t('hero.titleLine1'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: CivixColors.neel)),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            outcomes.isNotEmpty ? outcomes[_index % outcomes.length] : '',
            key: ValueKey(_index),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 14),
        Text(t('hero.description'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: CivixColors.neelSoft, height: 1.5)),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            CivixButton(
              label: t('hero.reportProblem'),
              variant: CivixButtonVariant.outline,
              icon: Icons.description_outlined,
              onPressed: () => context.push('/login/citizen'),
            ),
            CivixButton(
              label: t('hero.exploreCivix'),
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/login'),
            ),
          ],
        ),
      ],
    );
  }
}
