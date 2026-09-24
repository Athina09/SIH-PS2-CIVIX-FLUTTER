// Ported 1:1 from src/engines/socialSignal.ts
import '../models/types.dart';

const Map<Category, double> _categorySeverity = {
  'water-quality': 0.35,
  'water-scarcity': 0.3,
  'flooding-roads': 0.4,
  'power-lighting': 0.2,
  'agri-postharvest': 0.2,
  'agri-irrigation': 0.25,
  'wildlife-conflict': 0.35,
  'health-environment': 0.4,
  'livelihood-forest-produce': 0.2,
  'education-access': 0.2,
  'sanitation': 0.3,
  'other': 0.15,
};

const double autoEscalationThreshold = 0.75;
const String aiEscalationActor = 'AI Escalation Engine';

double aiConfidence({required bool verified, required Category category}) {
  final base = verified ? 0.55 : 0.3;
  final severity = _categorySeverity[category] ?? 0.15;
  return (base + severity).clamp(0.0, 1.0);
}

bool shouldAutoEscalate({required bool verified, required Category category}) {
  return aiConfidence(verified: verified, category: category) >= autoEscalationThreshold;
}
