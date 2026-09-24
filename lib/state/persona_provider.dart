// Ported from src/hooks/usePersona.ts
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/types.dart';
import 'civix_store.dart';

final personaProvider = Provider<Persona>((ref) {
  final session = ref.watch(civixStoreProvider.select((s) => s.session));
  return session.profile ?? guestPersona(session.role);
});
