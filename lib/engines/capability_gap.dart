// Ported 1:1 from src/engines/capabilityGap.ts
import '../models/types.dart';

const Map<String, List<String>> _equipmentKeywords = {
  'wildlife-conflict': ['thermal-imaging camera'],
  'water-quality': ['ICP-MS analyser', 'fluoride test kit'],
  'agri-postharvest': ['cold-chain prototyping kit'],
};

List<String> detectCapabilityGaps(List<String> disciplinesNeeded, List<Institution> topTeam, [String? category]) {
  final covered = <String>{
    for (final i in topTeam) ...i.disciplines,
    for (final i in topTeam) ...i.equipment.map((e) => e.toLowerCase()),
  };
  final missingDisciplines = disciplinesNeeded.where((d) => !covered.contains(d)).toList();
  final missingEquipment = category != null && _equipmentKeywords.containsKey(category)
      ? _equipmentKeywords[category]!.where((e) => !covered.contains(e.toLowerCase())).toList()
      : <String>[];
  return [...missingDisciplines, ...missingEquipment];
}
