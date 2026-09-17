import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/game/block_fusion_game.dart';
import 'package:block_fusion/main.dart';

void main() {
  testWidgets('tapping PLAY opens a game screen that actually fills the window',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BlockFusionApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY'));
    // Not pumpAndSettle: a running Flame game schedules frames forever, so
    // the tree never settles. Pump past the route transition instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));

    // Existence is not enough: a zero-sized Stack still "contains" its
    // children while painting nothing, which is exactly how this screen
    // shipped blank to the browser.
    final gameSize = tester.getSize(find.byType(GameWidget<BlockFusionGame>));
    expect(gameSize.width, greaterThan(300));
    expect(gameSize.height, greaterThan(600));

    final hud = find.textContaining('SCORE');
    expect(hud, findsOneWidget);
    final hudRect = tester.getRect(hud);
    expect(hudRect.width, greaterThan(0));
    expect(hudRect.top, greaterThanOrEqualTo(0));
    expect(hudRect.bottom, lessThan(844));
  });
}
