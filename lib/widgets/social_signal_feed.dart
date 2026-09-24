// Ported from src/components/ui/SocialSignalFeed.tsx
// Shared "social listening" feed used by both the citizen Channel Simulators screen and the
// government Inbox screen — kept as one widget so both stay visually and behaviourally in sync.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../engines/routing.dart';
import '../engines/social_signal.dart';
import '../models/types.dart';
import '../state/civix_store.dart';
import '../state/persona_provider.dart';
import '../theme/theme.dart';
import 'department_seal.dart';

const Map<String, ({Color bg, Color fg, String label, IconData icon})> _platformStyle = {
  'facebook': (bg: Color(0xFFE7F0FD), fg: Color(0xFF1877F2), label: 'Facebook', icon: Icons.facebook),
  'instagram': (bg: Color(0xFFFDEFF7), fg: Color(0xFFC13584), label: 'Instagram', icon: Icons.camera_alt_outlined),
  'telegram': (bg: Color(0xFFE6F5FC), fg: Color(0xFF229ED9), label: 'Telegram', icon: Icons.send),
  'x': (bg: Color(0xFFEDEDED), fg: Color(0xFF111111), label: 'X', icon: Icons.close),
};

class SocialSignalFeed extends ConsumerStatefulWidget {
  final int limit;
  final bool interactive;
  const SocialSignalFeed({super.key, this.limit = 6, this.interactive = true});

  @override
  ConsumerState<SocialSignalFeed> createState() => _SocialSignalFeedState();
}

class _SocialSignalFeedState extends ConsumerState<SocialSignalFeed> {
  int scanIndex = 0;
  Timer? _scanTimer;
  Timer? _escalateTimer;
  String? _lastScanningId;

  @override
  void initState() {
    super.initState();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      final pending = ref.read(civixStoreProvider).socialPosts.take(widget.limit).where((p) => p.converted != true).toList();
      if (pending.isEmpty) return;
      setState(() => scanIndex = (scanIndex + 1) % pending.length);
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _escalateTimer?.cancel();
    super.dispose();
  }

  void _maybeAutoEscalate(SocialPost? scanning) {
    if (scanning == null || scanning.id == _lastScanningId) return;
    _lastScanningId = scanning.id;
    _escalateTimer?.cancel();
    if (scanning.converted == true || !shouldAutoEscalate(verified: scanning.verified, category: scanning.category)) return;
    _escalateTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      ref.read(civixStoreProvider.notifier).convertSocialSignal(scanning.id, aiEscalationActor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(civixStoreProvider);
    final persona = ref.watch(personaProvider);
    final posts = store.socialPosts.take(widget.limit).toList();
    final pending = posts.where((p) => p.converted != true).toList();
    final scanning = pending.isNotEmpty ? pending[scanIndex % pending.length] : null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoEscalate(scanning));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: CivixColors.ember)),
            const SizedBox(width: 8),
            const Text('LIVE SOCIAL LISTENING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivixColors.ember, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 2),
        const Text('AI scans Facebook, Instagram, Telegram and X for civic complaints', style: TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        const SizedBox(height: 12),
        for (final p in posts) _buildPost(context, p, p.id == scanning?.id, store, persona.name),
      ],
    );
  }

  Widget _buildPost(BuildContext context, SocialPost p, bool scanning, CivixState store, String personaName) {
    final style = _platformStyle[p.platform] ?? _platformStyle['x']!;
    final dept = departmentByCategory[p.category]!;
    District? district;
    for (final d in store.districts) {
      if (d.id == p.districtId) district = d;
    }
    final confidence = aiConfidence(verified: p.verified, category: p.category);
    final autoEligible = shouldAutoEscalate(verified: p.verified, category: p.category);
    final role = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scanning ? role : CivixColors.rule, width: scanning ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
                  child: Icon(style.icon, size: 15, color: style.fg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(p.author, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                          if (p.verified) const Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.check_circle, size: 12, color: Colors.blue)),
                          Text(' · ${style.label} · ${DateFormat('d MMM').format(DateTime.tryParse(p.at) ?? DateTime.now())}',
                              style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('"${p.text}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 2),
                      const Text('REAL SOURCE — ORIGINAL PUBLIC POST', style: TextStyle(fontSize: 9, color: CivixColors.neelSoft, letterSpacing: 0.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: CivixColors.chuna, border: Border(top: BorderSide(color: CivixColors.rule))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI-EXTRACTED PROBLEM STATEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: CivixColors.neelSoft, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text('${p.category.replaceAll('-', ' ')} — ${district?.name ?? p.districtId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    DepartmentSeal(department: dept.department, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                          children: [
                            TextSpan(text: p.converted == true ? 'Routed to ' : 'Would route to '),
                            TextSpan(text: dept.department, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('AI confidence: ${(confidence * 100).round()}%', style: const TextStyle(fontSize: 10, color: CivixColors.neelSoft)),
                if (widget.interactive) ...[
                  const SizedBox(height: 8),
                  if (p.converted == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: CivixColors.lac),
                        const SizedBox(width: 4),
                        Text(autoEligible ? 'Auto-escalated by AI' : 'Converted to case', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.lac)),
                      ],
                    )
                  else if (autoEligible)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: role),
                        const SizedBox(width: 4),
                        Text('Escalating automatically…', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: role)),
                      ],
                    )
                  else
                    OutlinedButton(
                      onPressed: () => ref.read(civixStoreProvider.notifier).convertSocialSignal(p.id, personaName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: role,
                        side: BorderSide(color: role),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Convert to official case', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
