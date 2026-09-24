// Ported 1:1 from src/engines/replication.ts
import 'dart:math' as math;
import '../models/types.dart';
import 'util.dart';

typedef ReplicationVerdict = String; // 'REUSE' | 'ADAPT' | 'NEW RESEARCH'

class ReplicationResult {
  final String districtId;
  final double similarity;
  final ReplicationVerdict verdict;
  final String rationale;
  final String? adaptationNotes;

  ReplicationResult({
    required this.districtId,
    required this.similarity,
    required this.verdict,
    required this.rationale,
    this.adaptationNotes,
  });
}

List<ReplicationResult> replicationForProject(District sourceDistrict, List<District> districts) {
  final results = districts.where((d) => d.id != sourceDistrict.id).map((d) {
    final rainfallMatch = d.rainfall == sourceDistrict.rainfall
        ? 1.0
        : (d.rainfall == 'medium' || sourceDistrict.rainfall == 'medium' ? 0.5 : 0.0);
    final terrainOverlap = d.terrain.where((t) => sourceDistrict.terrain.contains(t)).length;
    final terrainMatch =
        sourceDistrict.terrain.isNotEmpty ? (terrainOverlap / sourceDistrict.terrain.length).clamp(0.0, 1.0) : 0.5;
    final popRatio = math.min(d.population, sourceDistrict.population) / math.max(d.population, sourceDistrict.population);
    final needSim = 1 - (d.needIndex - sourceDistrict.needIndex).abs() / 100;

    final score = round2(0.35 * rainfallMatch + 0.25 * terrainMatch + 0.2 * popRatio + 0.2 * needSim);

    String verdict;
    String rationale;
    String? adaptationNotes;
    if (score >= 0.8) {
      verdict = 'REUSE';
      rationale =
          '${d.name} closely matches ${sourceDistrict.name} in rainfall, terrain and need — the same design can be reused with minimal changes.';
    } else if (score >= 0.5) {
      verdict = 'ADAPT';
      rationale = '${d.name} shares some conditions with ${sourceDistrict.name} but differs enough to need adaptation.';
      adaptationNotes = terrainMatch < 0.5
          ? 'Different terrain — re-check foundation and drainage design.'
          : rainfallMatch < 1
              ? 'Different rainfall pattern — resize storage/capacity accordingly.'
              : 'Use stainless components if local water chemistry differs; verify with a local test.';
    } else {
      verdict = 'NEW RESEARCH';
      rationale = '${d.name} differs substantially from ${sourceDistrict.name} in conditions — treat this as a new research problem.';
    }
    return ReplicationResult(
      districtId: d.id,
      similarity: score,
      verdict: verdict,
      rationale: rationale,
      adaptationNotes: adaptationNotes,
    );
  }).toList();
  results.sort((a, b) => b.similarity.compareTo(a.similarity));
  return results;
}
