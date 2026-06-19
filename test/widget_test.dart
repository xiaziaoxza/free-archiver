import 'package:flutter_test/flutter_test.dart';

import 'package:free_archiver/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreeArchiverApp());
    // Verify the app renders without crashing
    expect(find.byType(FreeArchiverApp), findsOneWidget);
  });
}
