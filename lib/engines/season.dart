// Ported 1:1 from src/engines/season.ts
import '../models/types.dart';
import 'util.dart';

const Map<Category, Map<Season, double>> _matrix = {
  'flooding-roads': {'summer': 0.3, 'monsoon': 1.0, 'post-monsoon': 0.6, 'winter': 0.3},
  'water-scarcity': {'summer': 1.0, 'monsoon': 0.4, 'post-monsoon': 0.6, 'winter': 0.7},
  'water-quality': {'summer': 0.7, 'monsoon': 1.0, 'post-monsoon': 0.7, 'winter': 0.5},
  'agri-postharvest': {'summer': 0.8, 'monsoon': 0.5, 'post-monsoon': 1.0, 'winter': 0.7},
  'wildlife-conflict': {'summer': 0.5, 'monsoon': 0.7, 'post-monsoon': 1.0, 'winter': 0.6},
  'power-lighting': {'summer': 0.6, 'monsoon': 0.8, 'post-monsoon': 0.5, 'winter': 0.7},
  'agri-irrigation': {'summer': 1.0, 'monsoon': 0.4, 'post-monsoon': 0.6, 'winter': 0.8},
  'health-environment': {'summer': 0.6, 'monsoon': 0.9, 'post-monsoon': 0.6, 'winter': 0.5},
  'livelihood-forest-produce': {'summer': 0.5, 'monsoon': 0.5, 'post-monsoon': 1.0, 'winter': 0.6},
  'education-access': {'summer': 0.5, 'monsoon': 0.6, 'post-monsoon': 0.5, 'winter': 0.5},
  'sanitation': {'summer': 0.5, 'monsoon': 0.9, 'post-monsoon': 0.6, 'winter': 0.5},
  'other': {'summer': 0.5, 'monsoon': 0.5, 'post-monsoon': 0.5, 'winter': 0.5},
};

const Set<Category> _waterUp = {'flooding-roads', 'water-quality', 'health-environment'};
const Set<Category> _waterDown = {'water-scarcity', 'agri-irrigation'};

class SeasonalResult {
  final double value;
  final String explanation;
  SeasonalResult({required this.value, required this.explanation});
}

SeasonalResult seasonalMultiplier(Category category, Season season, double rainfallAnomalyPct, bool drought) {
  final base = _matrix[category]![season]!;
  double value = base;
  final notes = <String>[];

  if (rainfallAnomalyPct != 0) {
    final frac = rainfallAnomalyPct / 100;
    if (_waterUp.contains(category)) {
      value = clamp01(value * (1 + frac * 0.5));
      notes.add(
          'Rainfall ${frac > 0 ? '+' : ''}${rainfallAnomalyPct.toStringAsFixed(0)}% nudges this category ${frac > 0 ? 'up' : 'down'}');
    } else if (_waterDown.contains(category)) {
      value = clamp01(value * (1 - frac * 0.5));
      notes.add(
          'Rainfall ${frac > 0 ? '+' : ''}${rainfallAnomalyPct.toStringAsFixed(0)}% eases scarcity pressure${frac < 0 ? ' further raises urgency' : ''}');
    }
  }
  if (drought) {
    if (_waterDown.contains(category)) {
      value = clamp01(value * 1.3);
      notes.add('Drought flag raises urgency of water-scarcity categories');
    } else if (_waterUp.contains(category)) {
      value = clamp01(value * 0.8);
      notes.add('Drought flag slightly eases flooding/water-quality urgency');
    }
  }
  final seasonName = season.replaceAll('-', ' ');
  notes.insert(0,
      '${seasonName[0].toUpperCase()}${seasonName.substring(1)} sets a base seasonal weight of ${base.toStringAsFixed(1)}x for ${category.replaceAll('-', ' ')}');
  return SeasonalResult(value: round2(value), explanation: notes.join('. '));
}
