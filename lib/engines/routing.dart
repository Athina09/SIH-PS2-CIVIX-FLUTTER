// Ported 1:1 from src/engines/routing.ts
import '../models/types.dart';

class DeptScheme {
  final String department;
  final String? scheme;
  const DeptScheme(this.department, [this.scheme]);
}

const Map<Category, DeptScheme> departmentByCategory = {
  'water-quality': DeptScheme('PHED', 'Jal Jeevan Mission'),
  'water-scarcity': DeptScheme('PHED', 'Jal Jeevan Mission'),
  'flooding-roads': DeptScheme('Rural Works Dept'),
  'power-lighting': DeptScheme('Energy Dept'),
  'agri-postharvest': DeptScheme('Rural Works Dept'),
  'agri-irrigation': DeptScheme('PHED', 'Jal Jeevan Mission'),
  'wildlife-conflict': DeptScheme('Forest Dept'),
  'health-environment': DeptScheme('Health Dept'),
  'livelihood-forest-produce': DeptScheme('MGNREGA cell'),
  'education-access': DeptScheme('Energy Dept'),
  'sanitation': DeptScheme('Health Dept'),
  'other': DeptScheme('MGNREGA cell'),
};

RouteDecision recommendRoute({
  required Category category,
  required int repeatCount,
  bool? noSchemeMatch,
  bool? noSimilarSolution,
}) {
  final dept = departmentByCategory[category]!;

  if (repeatCount >= 2) {
    return RouteDecision(
      type: 'innovation',
      reason:
          'This issue has recurred $repeatCount times — a repair-and-forget response has not worked, so it is recommended for the Innovation Twin.',
      aiRecommended: 'innovation',
    );
  }
  if ((noSchemeMatch ?? false) ||
      (dept.scheme == null && (category == 'wildlife-conflict' || category == 'livelihood-forest-produce'))) {
    return RouteDecision(
      type: 'innovation',
      reason: 'No existing department scheme covers this problem directly, so it is recommended for the Innovation Twin.',
      aiRecommended: 'innovation',
    );
  }
  if (noSimilarSolution ?? false) {
    return RouteDecision(
      type: 'innovation',
      reason: 'No similar solution exists in Solution Memory, so it is recommended for the Innovation Twin.',
      aiRecommended: 'innovation',
    );
  }
  return RouteDecision(
    type: 'service',
    department: dept.department,
    scheme: dept.scheme,
    reason:
        'This is a routine ${category.replaceAll('-', ' ')} issue with an existing department pathway (${dept.department}${dept.scheme != null ? ' / ${dept.scheme}' : ''}).',
    aiRecommended: 'service',
  );
}
