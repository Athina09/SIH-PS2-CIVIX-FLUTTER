// Ported from src/store/a11y.ts
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontScale { normal, large, xl }

class A11yState {
  final FontScale fontScale;
  final bool highContrast;
  final bool dataSaver;
  final bool readAloud;

  const A11yState({
    this.fontScale = FontScale.normal,
    this.highContrast = false,
    this.dataSaver = false,
    this.readAloud = false,
  });

  A11yState copyWith({FontScale? fontScale, bool? highContrast, bool? dataSaver, bool? readAloud}) => A11yState(
        fontScale: fontScale ?? this.fontScale,
        highContrast: highContrast ?? this.highContrast,
        dataSaver: dataSaver ?? this.dataSaver,
        readAloud: readAloud ?? this.readAloud,
      );

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale.name,
        'highContrast': highContrast,
        'dataSaver': dataSaver,
        'readAloud': readAloud,
      };

  factory A11yState.fromJson(Map<String, dynamic> j) => A11yState(
        fontScale: FontScale.values.firstWhere((f) => f.name == j['fontScale'], orElse: () => FontScale.normal),
        highContrast: j['highContrast'] ?? false,
        dataSaver: j['dataSaver'] ?? false,
        readAloud: j['readAloud'] ?? false,
      );
}

const String kA11yPersistKey = 'civix-a11y-v2';

class A11yNotifier extends StateNotifier<A11yState> {
  A11yNotifier() : super(const A11yState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kA11yPersistKey);
      if (raw == null) return;
      state = A11yState.fromJson(jsonDecode(raw));
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kA11yPersistKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void setFontScale(FontScale s) {
    state = state.copyWith(fontScale: s);
    _persist();
  }

  void setHighContrast(bool v) {
    state = state.copyWith(highContrast: v);
    _persist();
  }

  void setDataSaver(bool v) {
    state = state.copyWith(dataSaver: v);
    _persist();
  }

  void setReadAloud(bool v) {
    state = state.copyWith(readAloud: v);
    _persist();
  }
}

final a11yStoreProvider = StateNotifierProvider<A11yNotifier, A11yState>((ref) => A11yNotifier());
