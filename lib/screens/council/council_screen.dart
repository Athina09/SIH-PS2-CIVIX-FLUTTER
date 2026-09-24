// Ported from src/features/council/CouncilPage.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/dictionary.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/panel.dart';

const _stages = ['problem', 'prototype', 'pilot', 'final'];
const _seats = ['reporter', 'panchayat', 'beneficiary', 'expert', 'official'];

class CouncilScreen extends ConsumerStatefulWidget {
  const CouncilScreen({super.key});

  @override
  ConsumerState<CouncilScreen> createState() => _CouncilScreenState();
}

class _CouncilScreenState extends ConsumerState<CouncilScreen> {
  String _stage = 'final';
  final Map<String, String> _comments = {};

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    final currentSeat = persona.councilSeat;

    return Scaffold(
      appBar: AppBar(title: Text(t('council.heading'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Row(
              children: [
                Text(t('council.votingAs'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (currentSeat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(t('council.seats.$currentSeat'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )
                else
                  Expanded(
                    child: Text(t('council.noSeatAssigned'),
                        style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: _stages.map((s) {
              final selected = s == _stage;
              return ChoiceChip(
                label: Text(t('council.stageLabels.$s')),
                selected: selected,
                onSelected: (_) => setState(() => _stage = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          for (final p in store.projects) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go('/projects/${p.id}'),
                            child: Text(p.title,
                                style: const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                          ),
                        ),
                        Builder(builder: (context) {
                          final votes = p.councilVotes.where((v) => v.stage == _stage).toList();
                          final total = votes.fold<double>(
                              0, (sum, v) => sum + (v.vote == 'yes' ? 1 : (v.vote == 'partial' ? 0.5 : 0)));
                          return Text(
                            t('council.seatsVoted', {'votes': '${votes.length}', 'total': total.toString()}),
                            style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final votes = p.councilVotes.where((v) => v.stage == _stage).toList();
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _seats.map((seat) {
                          final v = votes.where((x) => x.seat == seat);
                          final vote = v.isEmpty ? null : v.first;
                          Color color;
                          if (vote == null) {
                            color = CivixColors.neelSoft.withValues(alpha: 0.4);
                          } else if (vote.vote == 'yes') {
                            color = CivixColors.lac;
                          } else if (vote.vote == 'partial') {
                            color = CivixColors.tasar;
                          } else {
                            color = CivixColors.ember;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${t('council.seats.$seat')}${vote != null ? ': ${t('council.votes.${vote.vote}')}' : ''}',
                              style: TextStyle(fontSize: 10, color: color),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                    Builder(builder: (context) {
                      final votes = p.councilVotes.where((v) => v.stage == _stage).toList();
                      final myVote = currentSeat == null ? null : votes.where((v) => v.seat == currentSeat);
                      final hasVoted = myVote != null && myVote.isNotEmpty;
                      if (currentSeat == null || hasVoted) return const SizedBox.shrink();
                      final comment = _comments[p.id] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: t('council.commentPlaceholder'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _comments[p.id] = v),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final v in ['yes', 'partial', 'no']) ...[
                                  CivixButton(
                                    label: t('council.votes.$v'),
                                    size: CivixButtonSize.sm,
                                    variant: v == 'no' ? CivixButtonVariant.danger : CivixButtonVariant.secondary,
                                    onPressed: (v == 'no' && currentSeat == 'beneficiary' && comment.trim().isEmpty)
                                        ? null
                                        : () {
                                            final msg = notifier.castCouncilVote(
                                              p.id,
                                              persona.name,
                                              stage: _stage,
                                              seat: currentSeat,
                                              vote: v,
                                              comment: comment.isEmpty ? null : comment,
                                            );
                                            setState(() => _comments[p.id] = '');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(content: Text(msg)));
                                          },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
