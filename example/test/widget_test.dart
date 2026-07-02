import 'package:flutter_test/flutter_test.dart';

import 'package:background_runtime_example/main.dart';

void main() {
  testWidgets('Example app renders tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const BackgroundRuntimeExampleApp());

    expect(find.text('Background Runtime'), findsOneWidget);
    expect(find.text('Init'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Shutdown'), findsOneWidget);
  });
}
