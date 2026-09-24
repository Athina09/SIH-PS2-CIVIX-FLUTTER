// Ported from src/components/layout/RequireRole.tsx
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/civix_store.dart';

/// Returns a go_router redirect path if [role] doesn't match the current session role
/// (and no profile exists yet), else null to allow navigation through.
String? requireRoleRedirect(Ref ref, String role) {
  final session = ref.read(civixStoreProvider).session;
  if (session.profile == null || session.role != role) {
    return '/login/$role';
  }
  return null;
}
