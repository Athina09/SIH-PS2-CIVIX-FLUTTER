// Ported 1:1 from src/engines/similarity.ts
import '../models/types.dart';
import 'util.dart';

class SimilarityResult {
  final double score;
  final int categoryMatch;
  final double distanceKm;
  final double distanceScore;
  final int daysApart;
  final double timeScore;
  final bool isDuplicate;
  final List<String> explanation;

  SimilarityResult({
    required this.score,
    required this.categoryMatch,
    required this.distanceKm,
    required this.distanceScore,
    required this.daysApart,
    required this.timeScore,
    required this.isDuplicate,
    required this.explanation,
  });
}

SimilarityResult similarity({
  required Category category,
  required double lat,
  required double lng,
  required String createdAt,
  required MasterIssue issue,
}) {
  final categoryMatch = category == issue.category ? 1 : 0;
  final distanceKm = haversineKm(lat, lng, issue.lat, issue.lng);
  final distanceScore = (1 - distanceKm / 8).clamp(0.0, double.infinity);
  final daysApart =
      (DateTime.parse(createdAt).difference(DateTime.parse(issue.createdAt)).inMilliseconds.abs() / 86400000);
  final timeScore = (1 - daysApart / 30).clamp(0.0, double.infinity);

  final score = 0.5 * categoryMatch + 0.3 * distanceScore + 0.2 * timeScore;
  final explanation = [
    categoryMatch == 1 ? 'Same category as the master issue' : 'Different category',
    '${distanceKm.toStringAsFixed(1)} km apart (decays over 8 km)',
    '${daysApart.toStringAsFixed(0)} days apart (30-day window)',
  ];
  return SimilarityResult(
    score: round2(score),
    categoryMatch: categoryMatch,
    distanceKm: round2(distanceKm),
    distanceScore: round2(distanceScore),
    daysApart: daysApart.round(),
    timeScore: round2(timeScore),
    isDuplicate: score >= 0.75,
    explanation: explanation,
  );
}

class BestMatch {
  final MasterIssue issue;
  final SimilarityResult result;
  BestMatch({required this.issue, required this.result});
}

BestMatch? findBestMatch({
  required Category category,
  required double lat,
  required double lng,
  required String createdAt,
  required List<MasterIssue> issues,
}) {
  BestMatch? best;
  for (final issue in issues) {
    final result = similarity(category: category, lat: lat, lng: lng, createdAt: createdAt, issue: issue);
    if (best == null || result.score > best.result.score) {
      best = BestMatch(issue: issue, result: result);
    }
  }
  return best;
}
