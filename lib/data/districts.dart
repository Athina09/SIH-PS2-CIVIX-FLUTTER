// Ported 1:1 from src/data/districts.ts
import '../models/types.dart';

const Set<String> _tribalMajority = {
  'simdega', 'latehar', 'pakur', 'sahibganj', 'west-singhbhum', 'gumla', 'garhwa', 'khunti',
};
const Set<String> _highVoice = {'ranchi', 'dhanbad', 'east-singhbhum'};

class _Raw {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int population;
  final List<String> terrain;
  final String rainfall;
  const _Raw(this.id, this.name, this.lat, this.lng, this.population, this.terrain, this.rainfall);
}

const List<_Raw> _raw = [
  _Raw('ranchi', 'Ranchi', 23.34, 85.31, 2914253, ['plateau'], 'medium'),
  _Raw('dhanbad', 'Dhanbad', 23.80, 86.43, 2684487, ['coalfield'], 'medium'),
  _Raw('east-singhbhum', 'East Singhbhum', 22.86, 86.20, 2293919, ['industrial'], 'high'),
  _Raw('west-singhbhum', 'West Singhbhum', 22.55, 85.80, 1502338, ['forest', 'hilly'], 'high'),
  _Raw('bokaro', 'Bokaro', 23.67, 86.15, 2062330, ['coalfield'], 'medium'),
  _Raw('hazaribagh', 'Hazaribagh', 23.99, 85.36, 1734495, ['plateau'], 'medium'),
  _Raw('giridih', 'Giridih', 24.19, 86.30, 2445474, ['hilly'], 'medium'),
  _Raw('deoghar', 'Deoghar', 24.48, 86.70, 1492073, ['plateau'], 'medium'),
  _Raw('dumka', 'Dumka', 24.27, 87.25, 1321096, ['forest'], 'high'),
  _Raw('palamu', 'Palamu', 24.03, 84.07, 1939869, ['drought-prone'], 'low'),
  _Raw('gumla', 'Gumla', 23.04, 84.54, 1025213, ['forest', 'hilly'], 'high'),
  _Raw('simdega', 'Simdega', 22.62, 84.50, 599578, ['forest'], 'high'),
  _Raw('lohardaga', 'Lohardaga', 23.43, 84.68, 461738, ['forest'], 'medium'),
  _Raw('latehar', 'Latehar', 23.75, 84.50, 726978, ['forest', 'hilly'], 'high'),
  _Raw('garhwa', 'Garhwa', 24.16, 83.81, 1322784, ['drought-prone'], 'low'),
  _Raw('godda', 'Godda', 24.83, 87.21, 1313551, ['plateau'], 'medium'),
  _Raw('sahibganj', 'Sahibganj', 25.24, 87.64, 1150038, ['riverine'], 'high'),
  _Raw('pakur', 'Pakur', 24.63, 87.85, 900422, ['forest'], 'high'),
  _Raw('chatra', 'Chatra', 24.21, 84.87, 1042886, ['forest'], 'medium'),
  _Raw('koderma', 'Koderma', 24.47, 85.60, 717656, ['plateau'], 'medium'),
  _Raw('ramgarh', 'Ramgarh', 23.63, 85.52, 949443, ['coalfield'], 'medium'),
  _Raw('jamtara', 'Jamtara', 23.96, 86.80, 791042, ['plateau'], 'medium'),
  _Raw('khunti', 'Khunti', 23.07, 85.28, 530299, ['forest'], 'high'),
  _Raw('saraikela-kharsawan', 'Saraikela-Kharsawan', 22.70, 85.93, 1065056, ['forest', 'industrial'], 'high'),
];

int _round(double n) => n.round();

List<District> _build() {
  return _raw.map((d) {
    final tribal = _tribalMajority.contains(d.id);
    final voice = _highVoice.contains(d.id);
    final needIndex = tribal
        ? 62 + _round((d.population % 1000) / 40)
        : 30 + _round((d.population % 1000) / 60);
    final reportRate = voice
        ? 55 + _round((d.population % 500) / 20)
        : tribal
            ? 8 + _round((d.population % 300) / 60)
            : 25 + _round((d.population % 400) / 30);
    return District(
      id: d.id,
      name: d.name,
      lat: d.lat,
      lng: d.lng,
      population: d.population,
      needIndex: needIndex > 95 ? 95 : needIndex.toDouble(),
      reportRate: reportRate.toDouble(),
      terrain: d.terrain,
      rainfall: d.rainfall,
      tribalMajority: tribal,
    );
  }).toList();
}

final List<District> districts = _build();

District districtById(String id) => districts.firstWhere((d) => d.id == id);
