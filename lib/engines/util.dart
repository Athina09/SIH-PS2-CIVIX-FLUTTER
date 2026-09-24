import 'dart:math' as math;

double clamp01(double n) => n.clamp(0.0, 1.0);

double round2(double n) => (n * 100).round() / 100;

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.pow(math.sin(dLng / 2), 2);
  return r * 2 * math.asin(math.sqrt(a));
}

String titleCaseWords(String s) => s.replaceAll('-', ' ');
