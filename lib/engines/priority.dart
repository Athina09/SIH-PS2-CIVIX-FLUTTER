// Ported 1:1 from src/engines/priority.ts
import '../models/types.dart';
import 'equity.dart';
import 'season.dart';
import 'util.dart';

class PriorityResult {
  final double harm;
  final double people;
  final double equityGap;
  final double seasonal;
  final double total;
  final List<String> explanation;

  PriorityResult({
    required this.harm,
    required this.people,
    required this.equityGap,
    required this.seasonal,
    required this.total,
    required this.explanation,
  });

  PriorityBreakdown toBreakdown() => PriorityBreakdown(
        harm: harm,
        people: people,
        equityGap: equityGap,
        seasonal: seasonal,
        total: total,
        explanation: explanation,
      );
}

PriorityResult computePriority({
  required Category category,
  required int households,
  required int upvotes,
  required String districtId,
  required List<District> districts,
  required Season season,
  required double rainfallAnomalyPct,
  required bool drought,
}) {
  final harm = clamp01(0.5 + (households > 40 ? 0.3 : households > 15 ? 0.15 : 0));
  final people = clamp01((households / 80).clamp(0, 1) * 0.6 + (upvotes / 30).clamp(0, 1) * 0.4);
  final equityGap = equityGapFor(districts, districtId);
  final seasonal = seasonalMultiplier(category, season, rainfallAnomalyPct, drought);

  final total = (100 * (0.3 * harm + 0.25 * people + 0.2 * equityGap + 0.25 * seasonal.value)).round().toDouble();

  final explanation = [
    'Harm severity contributes ${(harm * 30).toStringAsFixed(0)} of 30 points based on households affected.',
    'People affected (households + upvotes) contributes ${(people * 25).toStringAsFixed(0)} of 25 points.',
    'Voice-need equity gap for this district contributes ${(equityGap * 20).toStringAsFixed(0)} of 20 points.',
    '${seasonal.explanation} — contributes ${(seasonal.value * 25).toStringAsFixed(0)} of 25 points.',
  ];

  return PriorityResult(
    harm: round2(harm),
    people: round2(people),
    equityGap: round2(equityGap),
    seasonal: round2(seasonal.value),
    total: total,
    explanation: explanation,
  );
}
