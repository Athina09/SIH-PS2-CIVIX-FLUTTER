// Ported 1:1 from src/engines/lessons.ts
import '../models/types.dart';

List<FailureLesson> lessonsForCategory(Category category, List<FailureLesson> lessons) {
  return lessons.where((l) => l.category == category).toList();
}
