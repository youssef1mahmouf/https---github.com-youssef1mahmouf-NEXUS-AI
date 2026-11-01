import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/app.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const NexusApp());
    expect(find.text('Nexus AI'), findsOneWidget);
  });
}

