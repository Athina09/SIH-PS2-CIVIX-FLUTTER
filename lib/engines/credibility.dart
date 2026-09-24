// Ported 1:1 from src/engines/credibility.ts
import '../models/types.dart';

int recomputeOverall({
  required double timeliness,
  required double qrSuccess,
  required double councilApproval,
  required double maintenance,
}) {
  return (0.25 * timeliness + 0.3 * qrSuccess + 0.25 * councilApproval + 0.2 * maintenance).round();
}

double _clamp(double n) => n.clamp(0, 100);

CredibilityProfile applyDelta(
  CredibilityProfile profile,
  String field, // timeliness | qrSuccess | councilApproval | maintenance
  double delta,
  String reason,
  String projectId,
) {
  double timeliness = profile.timeliness;
  double qrSuccess = profile.qrSuccess;
  double councilApproval = profile.councilApproval;
  double maintenance = profile.maintenance;
  switch (field) {
    case 'timeliness':
      timeliness = _clamp(profile.timeliness + delta);
      break;
    case 'qrSuccess':
      qrSuccess = _clamp(profile.qrSuccess + delta);
      break;
    case 'councilApproval':
      councilApproval = _clamp(profile.councilApproval + delta);
      break;
    case 'maintenance':
      maintenance = _clamp(profile.maintenance + delta);
      break;
  }
  final overall = recomputeOverall(
    timeliness: timeliness,
    qrSuccess: qrSuccess,
    councilApproval: councilApproval,
    maintenance: maintenance,
  ).toDouble();
  final history = [...profile.history, CredibilityHistoryEntry(projectId: projectId, delta: delta, reason: reason)];
  return CredibilityProfile(
    timeliness: timeliness,
    qrSuccess: qrSuccess,
    councilApproval: councilApproval,
    maintenance: maintenance,
    overall: overall,
    history: history,
  );
}
