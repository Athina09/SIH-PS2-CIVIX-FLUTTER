// Ported 1:1 from src/engines/duplicateCheck.ts
// Shared content-hash duplicate check, reused wherever a citizen or team member uploads a file
// (funds-allocation docs, milestone proof, evidence photos/videos) so a reused or resubmitted
// file gets flagged consistently across the app instead of each screen inventing its own check.
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

T? findDuplicateByHash<T>(String? hash, List<T> corpus, String? Function(T) hashOf) {
  if (hash == null) return null;
  for (final item in corpus) {
    if (hashOf(item) == hash) return item;
  }
  return null;
}

String hashBytes(Uint8List bytes) {
  return sha256.convert(bytes).toString();
}

String hashText(String text) => hashBytes(Uint8List.fromList(utf8.encode(text)));
