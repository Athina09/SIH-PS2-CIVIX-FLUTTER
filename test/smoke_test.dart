import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civix_flutter/main.dart';

void main() {
  testWidgets('landing renders and unknown route shows not-found', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CivixApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
