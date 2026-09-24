// Ported from src/components/ui/DepartmentSeal.tsx
// A recognizable icon + colour per department, so someone who can't read the name can still
// tell departments apart at a glance.
import 'package:flutter/material.dart';

class _SealSpec {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _SealSpec(this.icon, this.bg, this.fg);
}

const Map<String, _SealSpec> _departmentSeal = {
  'PHED': _SealSpec(Icons.water_drop, Color(0xFFDCEEFB), Color(0xFF0B6FA8)),
  'Rural Works Dept': _SealSpec(Icons.construction, Color(0xFFF5E6D3), Color(0xFF8A5A1E)),
  'Energy Dept': _SealSpec(Icons.bolt, Color(0xFFFDF1CE), Color(0xFF95720C)),
  'Forest Dept': _SealSpec(Icons.forest, Color(0xFFDEEFDC), Color(0xFF276B3F)),
  'Health Dept': _SealSpec(Icons.favorite, Color(0xFFFBE1E1), Color(0xFFB23A3A)),
  'MGNREGA cell': _SealSpec(Icons.groups, Color(0xFFE9E2F7), Color(0xFF5B3FA3)),
};

const _SealSpec _fallbackSeal = _SealSpec(Icons.apartment, Color(0xFFEAEAEA), Color(0xFF555555));

class DepartmentSeal extends StatelessWidget {
  final String department;
  final double size;
  const DepartmentSeal({super.key, required this.department, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final spec = _departmentSeal[department] ?? _fallbackSeal;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: spec.bg,
        shape: BoxShape.circle,
        border: Border.all(color: spec.fg, width: 2),
      ),
      child: Icon(spec.icon, size: size * 0.5, color: spec.fg),
    );
  }
}
