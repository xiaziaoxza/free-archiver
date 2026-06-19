import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:free_archiver/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreeArchiverApp());
    expect(find.text('自由解压'), findsNothing); // Title is in AppBar, not immediate text
  });
}
