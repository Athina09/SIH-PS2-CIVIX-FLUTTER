// Ported 1:1 from src/engines/chain.ts
import '../models/types.dart';

const List<String> lifecycleSteps = [
  'Report', 'Verify', 'Merge', 'Prioritise', 'Route', 'Build', 'Deploy', 'Validate', 'Scale',
];
const List<String> lifecycleStepsHi = [
  'रिपोर्ट', 'सत्यापन', 'विलय', 'प्राथमिकता', 'मार्ग', 'निर्माण', 'तैनाती', 'पुष्टि', 'विस्तार',
];

int chainStep(MasterIssue issue, [Project? project]) {
  if (project != null) {
    switch (project.stage) {
      case 'team-forming':
      case 'pending-approval':
      case 'building':
        return 5;
      case 'piloting':
      case 'deployed':
        return 6;
      case 'community-validated':
        return 7;
      case 'scaled':
        return 8;
      case 'failed':
        return 6;
    }
  }
  switch (issue.stage) {
    case 'awaiting-validation':
      return 0;
    case 'validated':
      return 3;
    case 'routed-service':
    case 'routed-innovation':
      return 4;
    case 'in-project':
      return 5;
    case 'resolved':
      return 6;
    case 'closed-failed':
      return 6;
  }
  return 0;
}

String chainStepLabel(int step) {
  final i = step.clamp(0, lifecycleSteps.length - 1);
  return lifecycleSteps[i];
}
