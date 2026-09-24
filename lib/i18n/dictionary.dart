// Mirrors src/i18n/index.ts + the useDictionary() hook pattern used across the React app,
// where screens call `t.section.key` — here callers call `t('section.key')`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'en.dart';
import 'hi.dart';
import '../state/civix_store.dart';
import '../state/session.dart';

const Map<String, Map<String, dynamic>> dictionaries = {'en': enDict, 'hi': hiDict};

class AppDictionary {
  final Map<String, dynamic> _map;
  const AppDictionary(this._map);

  /// Dot-path lookup, e.g. t('nav.home') or t('reportWizard.confidence.strong').
  dynamic raw(String path) {
    dynamic node = _map;
    for (final part in path.split('.')) {
      if (node is Map<String, dynamic> && node.containsKey(part)) {
        node = node[part];
      } else {
        return path;
      }
    }
    return node;
  }

  /// String lookup with optional {param} interpolation, e.g. t('inbox.aiAnalysed', {'count': '3'}).
  String call(String path, [Map<String, String>? params]) {
    final value = raw(path);
    var str = value is String ? value : path;
    if (params != null) {
      params.forEach((key, val) {
        str = str.replaceAll('{$key}', val);
      });
    }
    return str;
  }

  List<String> list(String path) {
    final value = raw(path);
    if (value is List) return value.cast<String>();
    return [];
  }

  List<Map<String, dynamic>> listOfMaps(String path) {
    final value = raw(path);
    if (value is List) return value.cast<Map<String, dynamic>>();
    return [];
  }
}

final dictionaryProvider = Provider<AppDictionary>((ref) {
  final lang = ref.watch(civixStoreProvider.select((s) => s.session.lang));
  return AppDictionary(lang == AppLang.hi ? hiDict : enDict);
});
