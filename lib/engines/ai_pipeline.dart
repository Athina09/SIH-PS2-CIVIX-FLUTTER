// Ported 1:1 from src/engines/aiPipeline.ts
import '../models/types.dart';
import 'routing.dart';

const Map<Category, List<String>> _categoryKeywords = {
  'water-quality': ['fluoride', 'yellow water', 'dirty water', 'contaminated', 'stained', 'पानी पीला', 'फ्लोराइड'],
  'water-scarcity': ['hand pump', 'no water', 'dry well', 'handpump', 'हैंडपंप', 'पानी नहीं'],
  'flooding-roads': ['flood', 'culvert', 'waterlogged', 'road washed', 'submerged', 'बाढ़', 'सड़क'],
  'power-lighting': ['streetlight', 'no electricity', 'power cut', 'बिजली'],
  'agri-postharvest': ['rotting', 'cold storage', 'post-harvest', 'crop spoil', 'सड़ रहे'],
  'agri-irrigation': ['irrigation', 'pump failed', 'solar pump', 'सिंचाई'],
  'wildlife-conflict': ['elephant', 'wildlife', 'crop raid', 'हाथी', 'जंगली जानवर'],
  'health-environment': ['coal dust', 'pollution', 'unsafe water', 'health risk', 'प्रदूषण'],
  'livelihood-forest-produce': ['lac', 'mahua', 'forest produce', 'low price', 'लाख', 'महुआ'],
  'education-access': ['anganwadi', 'school', 'no electricity school', 'आंगनवाड़ी'],
  'sanitation': ['toilet', 'open defecation', 'sanitation', 'शौचालय'],
  'other': [],
};

class DepartmentSuggestion {
  final String department;
  final Category category;
  final String? scheme;
  final double confidence;
  final String reason;
  DepartmentSuggestion({
    required this.department,
    required this.category,
    this.scheme,
    required this.confidence,
    required this.reason,
  });
}

class ExtractedFields {
  final String place;
  final int urgency;
  final String affectedGroup;
  final String time;
  ExtractedFields({required this.place, required this.urgency, required this.affectedGroup, required this.time});
}

class AIPipelineResult {
  final String transcript;
  final String translation;
  final Category category;
  final ExtractedFields extractedFields;
  final List<String> missingDetails;
  final String structuredTitle;
  final List<DepartmentSuggestion> departmentSuggestions;
  AIPipelineResult({
    required this.transcript,
    required this.translation,
    required this.category,
    required this.extractedFields,
    required this.missingDetails,
    required this.structuredTitle,
    required this.departmentSuggestions,
  });
}

/// Ranks up to [max] distinct departments the report could be routed to, each with a confidence score.
List<DepartmentSuggestion> suggestDepartments(String text, [int max = 3]) {
  final lower = text.toLowerCase();
  final scored = _categoryKeywords.entries
      .map((e) => (category: e.key, matches: e.value.where((w) => lower.contains(w.toLowerCase())).length))
      .toList()
    ..sort((a, b) => b.matches.compareTo(a.matches));

  final picked = <({Category category, int matches, String department, String? scheme})>[];
  final seenDepts = <String>{};
  for (final s in scored) {
    final dept = departmentByCategory[s.category]!;
    if (seenDepts.contains(dept.department)) continue;
    seenDepts.add(dept.department);
    picked.add((category: s.category, matches: s.matches, department: dept.department, scheme: dept.scheme));
    if (picked.length >= max) break;
  }

  final weights = picked.map((p) => p.matches + 1).toList();
  final total = weights.fold(0, (a, b) => a + b);

  return List.generate(picked.length, (i) {
    final p = picked[i];
    return DepartmentSuggestion(
      department: p.department,
      category: p.category,
      scheme: p.scheme,
      confidence: (weights[i] / total * 100).round() / 100,
      reason: p.matches > 0
          ? 'Matched ${p.matches} keyword${p.matches > 1 ? 's' : ''} typical of ${p.category.replaceAll('-', ' ')} cases handled by ${p.department}.'
          : 'Plausible fallback — ${p.department} also handles general ${p.category.replaceAll('-', ' ')} matters.',
    );
  });
}

Category classifyCategory(String text) {
  final lower = text.toLowerCase();
  Category best = 'other';
  int bestCount = 0;
  for (final entry in _categoryKeywords.entries) {
    final count = entry.value.where((w) => lower.contains(w.toLowerCase())).length;
    if (count > bestCount) {
      bestCount = count;
      best = entry.key;
    }
  }
  return best;
}

AIPipelineResult runAiPipeline({String? rawText, required String village, int? households}) {
  final transcript = rawText ?? '';
  final translation = rawText ?? '';
  final category = classifyCategory('$transcript $translation');
  final missingDetails = <String>[];
  if (households == null) missingDetails.add('How many households are affected?');

  return AIPipelineResult(
    transcript: transcript,
    translation: translation,
    category: category,
    extractedFields: ExtractedFields(
      place: village,
      urgency: 3,
      affectedGroup: 'local residents',
      time: DateTime.now().toIso8601String(),
    ),
    missingDetails: missingDetails,
    structuredTitle: '${category.replaceAll('-', ' ')} reported in $village',
    departmentSuggestions: suggestDepartments('$transcript $translation'),
  );
}

const List<String> aiPipelineStages = [
  'Transcribing',
  'Translating',
  'Extracting fields',
  'Checking for similar reports',
  'Writing case summary',
];
