import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_ai/features/chat/widgets/holographic_orb.dart';

void main() {
  testWidgets(
    'HolographicOrb paints through a full animation cycle without asserting',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: HolographicOrb(size: 220))),
        ),
      );
      // Advance the animation through many frames so startAngle sweeps through
      // the range that previously violated Gradient.sweep's startAngle < endAngle
      // (endAngle defaults to 2pi; startAngle = t*2pi + i exceeds 2pi for i = 1, 2).
      for (int i = 0; i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(HolographicOrb), findsOneWidget);
    },
  );

  testWidgets('HolographicOrb survives repeated AnimatedSwitcher transitions', (
    tester,
  ) async {
    bool showOrb = true;
    for (int i = 0; i < 10; i++) {
      showOrb = !showOrb;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1),
              child: showOrb
                  ? const HolographicOrb(size: 220, key: ValueKey('orb'))
                  : const SizedBox(key: ValueKey('box')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Remount the orb one last time and let it animate.
    showOrb = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1),
            child: const HolographicOrb(size: 220, key: ValueKey('orb')),
          ),
        ),
      ),
    );
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.byType(HolographicOrb), findsOneWidget);
  });
}
