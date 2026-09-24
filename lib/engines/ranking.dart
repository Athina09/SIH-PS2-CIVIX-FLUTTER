// Ported 1:1 from src/engines/ranking.ts
import '../models/types.dart';
import 'util.dart';

class RankFactors {
  final double expertise;
  final double lab;
  final double location;
  final double availability;
  final double credibility;
  RankFactors({
    required this.expertise,
    required this.lab,
    required this.location,
    required this.availability,
    required this.credibility,
  });

  double operator [](String key) {
    switch (key) {
      case 'expertise':
        return expertise;
      case 'lab':
        return lab;
      case 'location':
        return location;
      case 'availability':
        return availability;
      case 'credibility':
        return credibility;
    }
    throw ArgumentError(key);
  }
}

class RankedInstitution {
  final Institution institution;
  final double score;
  final RankFactors factors;
  RankedInstitution({required this.institution, required this.score, required this.factors});
}

List<RankedInstitution> rankInstitutions(
  List<String> disciplinesNeeded,
  double issueLat,
  double issueLng,
  List<Institution> institutions,
) {
  final ranked = institutions.map((inst) {
    final overlap = disciplinesNeeded.where((d) => inst.disciplines.contains(d)).length;
    final expertise = disciplinesNeeded.isNotEmpty ? overlap / disciplinesNeeded.length : 0.0;
    final lab = (inst.labs.length / 2).clamp(0.0, 1.0);
    final distKm = haversineKm(issueLat, issueLng, inst.lat, inst.lng);
    final location = (1 - distKm / 250).clamp(0.0, double.infinity);
    final availability = inst.availability / 100;
    final credibility = inst.credibility.overall / 100;
    final score = 0.3 * expertise + 0.2 * lab + 0.15 * location + 0.15 * availability + 0.2 * credibility;
    return RankedInstitution(
      institution: inst,
      score: round2(score),
      factors: RankFactors(
        expertise: round2(expertise),
        lab: round2(lab),
        location: round2(location),
        availability: round2(availability),
        credibility: round2(credibility),
      ),
    );
  }).toList();
  ranked.sort((a, b) => b.score.compareTo(a.score));
  return ranked;
}

List<RankedInstitution> topInstitutions(
  List<String> disciplinesNeeded,
  double lat,
  double lng,
  List<Institution> institutions, {
  int n = 3,
}) {
  final ranked = rankInstitutions(disciplinesNeeded, lat, lng, institutions);
  return ranked.take(n).toList();
}

List<String> requiredCapabilities(ProblemStatement ps) => ps.disciplinesNeeded;

const List<Map<String, String>> _factorRows = [
  {'key': 'expertise', 'label': 'Discipline expertise match'},
  {'key': 'lab', 'label': 'Lab infrastructure'},
  {'key': 'location', 'label': 'Proximity to the issue'},
  {'key': 'availability', 'label': 'Team availability'},
  {'key': 'credibility', 'label': 'Track record / credibility'},
];

class FactorComparison {
  final String label;
  final double winner;
  final double candidate;
  final String edge; // winner | candidate | tie
  FactorComparison({required this.label, required this.winner, required this.candidate, required this.edge});
}

class SelectionExplanation {
  final String summary;
  final String? improvement;
  final List<FactorComparison> factors;
  SelectionExplanation({required this.summary, this.improvement, required this.factors});
}

/// Compares a losing institution's ranked factors against the one that was actually picked for
/// an issue, so a university can see exactly why — same factor weights as [rankInstitutions].
SelectionExplanation explainSelection(RankedInstitution winner, RankedInstitution candidate) {
  final factors = _factorRows.map((row) {
    final key = row['key']!;
    final label = row['label']!;
    final w = winner.factors[key];
    final c = candidate.factors[key];
    final edge = w > c ? 'winner' : (c > w ? 'candidate' : 'tie');
    return FactorComparison(label: label, winner: w, candidate: c, edge: edge);
  }).toList();

  final winnerEdges = factors.where((f) => f.edge == 'winner').toList()
    ..sort((a, b) => (b.winner - b.candidate).compareTo(a.winner - a.candidate));
  final candidateEdges = factors.where((f) => f.edge == 'candidate').toList();
  final top = winnerEdges.isNotEmpty ? winnerEdges.first : null;

  final summary = top != null
      ? '${winner.institution.name} was ranked ahead of ${candidate.institution.name} mainly on ${top.label.toLowerCase()} (${(top.winner * 100).round()}% vs ${(top.candidate * 100).round()}%). Overall match score: ${(winner.score * 100).round()}% vs ${(candidate.score * 100).round()}%.'
      : '${winner.institution.name} and ${candidate.institution.name} scored closely on every factor — the decision came down to a small overall margin (${(winner.score * 100).round()}% vs ${(candidate.score * 100).round()}%).';
  final improvement = candidateEdges.isNotEmpty
      ? 'You actually led on ${candidateEdges.map((f) => f.label.toLowerCase()).join(', ')} — worth highlighting in your next proposal for a similar challenge.'
      : null;
  return SelectionExplanation(summary: summary, improvement: improvement, factors: factors);
}
