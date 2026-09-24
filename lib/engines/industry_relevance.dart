// Ported 1:1 from src/engines/industryRelevance.ts
import '../models/types.dart';

const Map<Category, List<String>> _categoryKeywords = {
  'water-quality': ['water', 'water quality', 'sanitation'],
  'water-scarcity': ['water', 'irrigation'],
  'flooding-roads': ['infrastructure'],
  'power-lighting': ['solar', 'infrastructure', 'energy'],
  'agri-postharvest': ['cold-storage', 'livelihood', 'manufacturing'],
  'agri-irrigation': ['irrigation', 'solar', 'water'],
  'wildlife-conflict': ['livelihood', 'community mobilisation', 'environment'],
  'health-environment': ['health', 'environment', 'water quality'],
  'livelihood-forest-produce': ['livelihood', 'community mobilisation', 'fabrication'],
  'education-access': ['skilling', 'community mobilisation'],
  'sanitation': ['sanitation', 'water quality', 'health'],
  'other': [],
};

class RelevanceResult {
  final double score; // 0-1
  final List<String> reasons;
  RelevanceResult({required this.score, required this.reasons});
}

/// How well a project fits a CSR partner's own profile — used to help them decide whether to
/// fund it, not to gate anything. Weighted: district presence, expertise-to-category overlap,
/// and whether the partner's offer types (funding/equipment/etc.) match what's still needed.
RelevanceResult scoreRelevance(IndustryPartner partner, Project project, [Category? category]) {
  final reasons = <String>[];
  double score = 0;

  if (partner.districtIds.contains(project.districtId)) {
    score += 0.35;
    reasons.add("You're already active in this district");
  }

  final wanted = category != null ? (_categoryKeywords[category] ?? []) : <String>[];
  final expertiseHits = partner.expertise
      .where((e) => wanted.any((w) => e.toLowerCase().contains(w) || w.contains(e.toLowerCase())))
      .toList();
  if (expertiseHits.isNotEmpty) {
    score += (expertiseHits.length * 0.2).clamp(0, 0.4);
    reasons.add('Matches your registered expertise: ${expertiseHits.join(', ')}');
  }

  final stillNeedsFunding = project.milestones.any((m) => m.status == 'pending' || m.status == 'submitted');
  if (stillNeedsFunding && partner.offerTypes.contains('funding')) {
    score += 0.15;
    reasons.add('You offer funding, and this project still has unfunded milestones');
  }
  final otherOfferMatch = partner.offerTypes.where((t) => t != 'funding').toList();
  if (otherOfferMatch.isNotEmpty) {
    score += 0.1;
    reasons.add('You can also contribute ${otherOfferMatch.join(', ')}');
  }

  score = score.clamp(0.08, 1.0);
  if (reasons.isEmpty) {
    reasons.add(
        'Limited overlap with your registered districts or expertise — a stretch opportunity outside your usual profile.');
  }
  return RelevanceResult(score: (score * 100).round() / 100, reasons: reasons);
}
