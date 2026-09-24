// Ported 1:1 from src/engines/equity.ts
import '../models/types.dart';
import 'util.dart';

class EquityResult {
  final String districtId;
  final double needPercentile;
  final double reportRatePercentile;
  final double equityGap;
  final bool flagged;

  EquityResult({
    required this.districtId,
    required this.needPercentile,
    required this.reportRatePercentile,
    required this.equityGap,
    required this.flagged,
  });
}

double _percentileRank(List<double> values, double value) {
  final sorted = [...values]..sort();
  final below = sorted.where((v) => v < value).length;
  return sorted.length <= 1 ? 0.5 : below / (sorted.length - 1);
}

List<EquityResult> computeEquity(List<District> districts) {
  final needs = districts.map((d) => d.needIndex).toList();
  final rates = districts.map((d) => d.reportRate).toList();
  return districts.map((d) {
    final needPercentile = _percentileRank(needs, d.needIndex);
    final reportRatePercentile = _percentileRank(rates, d.reportRate);
    final equityGap = clamp01(needPercentile - reportRatePercentile);
    return EquityResult(
      districtId: d.id,
      needPercentile: round2(needPercentile),
      reportRatePercentile: round2(reportRatePercentile),
      equityGap: round2(equityGap),
      flagged: needPercentile > 0.6 && reportRatePercentile < 0.4,
    );
  }).toList();
}

double equityGapFor(List<District> districts, String districtId) {
  final results = computeEquity(districts);
  final match = results.where((r) => r.districtId == districtId);
  return match.isEmpty ? 0 : match.first.equityGap;
}
