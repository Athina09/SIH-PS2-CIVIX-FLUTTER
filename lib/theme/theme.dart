// Ported from src/index.css design tokens + src/lib/utils.ts ROLE_COLORS.
import 'package:flutter/material.dart';

class CivixColors {
  static const chuna = Color(0xFFE7EEF6);
  static const page = Color(0xFFF8FAFD);
  static const neel = Color(0xFF1C2B5A);
  static const neelSoft = Color(0xFF56628A);
  static const rule = Color(0xFFC5D0E2);
  static const ruleHairline = Color(0xFFDCE3EF);

  static const lac = Color(0xFFB3123F);
  static const sal = Color(0xFF2F6B3F);
  static const tasar = Color(0xFFC79A2E);
  static const kusum = Color(0xFF5B4B8A);
  static const ember = Color(0xFFC4471A);
}

const Map<String, Color> roleColors = {
  'citizen': CivixColors.lac,
  'government': CivixColors.neel,
  'university': CivixColors.sal,
  'industry': CivixColors.tasar,
  'council': CivixColors.kusum,
};

Color roleColorOf(String? role) => roleColors[role] ?? CivixColors.neel;

ThemeData civixTheme({String? role, bool highContrast = false}) {
  final accent = highContrast ? Colors.black : roleColorOf(role);
  final bg = highContrast ? Colors.white : CivixColors.chuna;
  final onBg = highContrast ? Colors.black : CivixColors.neel;

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      surface: CivixColors.page,
      brightness: Brightness.light,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme().apply(bodyColor: onBg, displayColor: onBg),
    appBarTheme: AppBarTheme(
      backgroundColor: CivixColors.page.withValues(alpha: 0.95),
      foregroundColor: onBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(top: BorderSide(color: accent, width: 3)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: CivixColors.rule),
      ),
    ),
    dividerTheme: const DividerThemeData(color: CivixColors.rule),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 44),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 44),
      ),
    ),
  );
}

String formatCurrency(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  final digits = s.replaceAll('-', '');
  final neg = s.startsWith('-');
  // Indian digit grouping: last 3 digits, then groups of 2.
  final parts = <String>[];
  if (digits.length > 3) {
    parts.add(digits.substring(digits.length - 3));
    var rest = digits.substring(0, digits.length - 3);
    while (rest.length > 2) {
      parts.add(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.add(rest);
  } else {
    parts.add(digits);
  }
  buf.write(parts.reversed.join(','));
  return '${neg ? '-' : ''}₹$buf';
}
