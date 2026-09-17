---
name: flame-game
description: Building 2D games with the Flame engine on top of Flutter — component tree and coordinate spaces, drag-and-drop placement, keeping game rules testable, and driving real gestures in tests. Use when adding or debugging anything under lib/game/ (FlameGame, PositionComponent, DragCallbacks, GameWidget), when a piece lands on the wrong cell or a drag does nothing, or when writing tests for gameplay interaction rather than pure logic.
---

# Flame game development

Non-obvious rules learned from building this game. Flame's own docs cover the
API surface; this covers what the docs do not say clearly and what silently
produces a game that compiles, passes `flutter analyze`, and is still broken.

## Coordinate spaces: where you add a component decides its math

`FlameGame` adds a `CameraComponent` and a `World` as its own children in its
constructor. So there are two different spaces:

- `game.add(c)` — `c` becomes a **sibling of the camera and world**. It renders
  in root/screen space: its `position` is 1:1 with widget pixels, untouched by
  camera transforms. This is the right place for a fixed board, a tray, HUD-like
  components — anything that should not pan or zoom.
- `game.world.add(c)` — `c` lives inside the camera's world and is subject to
  the viewfinder/viewport transform.

Components in different spaces cannot have their positions compared or
subtracted. If a draggable piece is a child of a tray component but the board is
a child of the game, then `piece.position - board.position` is meaningless and
pieces will land on the wrong cell.

**Rule:** anything whose positions you compare must share one parent. When a
controller manages pieces that must hit-test against the board, have it add them
to the same parent as the board (`game.add(...)`), not to itself. A plain
controller class that is not a `Component` at all is often the cleanest way to
own the lifecycle without becoming a coordinate-space boundary.

## Drag and drop

- `DragCallbacks` is a mixin on the **component**, not the game. Modern Flame
  (>= 1.9) needs no `HasDraggables`/`HasTappables` on `FlameGame`; the mixin
  registers itself with the event dispatcher in `onMount`.
- Follow the pointer with `position.add(event.localDelta)` in `onDragUpdate`.
  `localDelta` is movement since the last event, not an absolute position — so
  the component's `position` ends at `home + totalDragDelta`, which is *not*
  where the pointer is (the grab point is usually not the component's anchor).
  Compute drops from the component's position, not the pointer's.
- `PositionComponent.containsLocalPoint` already hit-tests the bounding box.
  Do not override it for irregular shapes — grabbing an L-piece by its empty
  corner is good UX in a casual game.
- Default anchor is `Anchor.topLeft`, so `position` is the top-left corner.
  Do not pass `anchor:` just to restate the default.
- Raise `priority` in `onDragStart` and drop it in `onDragEnd` so the dragged
  piece renders above the board.
- Implement `onDragCancel` too, or an interrupted drag leaves the piece stranded
  mid-board.

## Rebuild from state; do not let components remove themselves

When a placement succeeds, the natural instinct is `removeFromParent()` inside
the component's own `onDragEnd`. Avoid it. If the game state is a
`ChangeNotifier`, `notifyListeners()` runs **synchronously inside**
`tryPlace(...)`, so any listener that also rebuilds the piece list runs while
that component is still mid-handler — two code paths now race to remove the same
component.

Instead: one listener reconciles the whole set of pieces against the state
(remove all, re-add for each non-null slot). Pieces never remove themselves.
With at most a handful of pieces this is cheaper than the bookkeeping it
replaces, and it cannot drift out of sync with the state.

## What needs change notification and what does not

Flame re-renders every frame. A component's `render()` may read live game state
directly — no dirty flags, no notifications, no per-cell components. Painting an
8x8 board is one `render()` that loops the grid and draws rects.

Only Flutter widgets **outside** the canvas (score HUD, game-over overlay) need
`ChangeNotifier` + `ListenableBuilder`. Keep that notifier in the logic layer,
not in the components.

## Layout

Recompute sizes in `onGameResize(Vector2 size)`, not once in `onLoad`.
`onGameResize` can fire before `onLoad` finishes, so hold layout targets in
nullable fields, guard the calls (`_grid?.layout(size)`), and also call layout at
the end of `onLoad` with the current `size`. Derive a `cellSize` from the canvas
and let every component size off it; never hardcode pixel sizes.

## Testing gameplay, not just logic

Split the rules (grid, scoring, game-over) into plain Dart with no Flame imports
and unit-test them. That is necessary but **not sufficient** — it proves nothing
about whether a drag actually places a piece.

Drive real gestures through `GameWidget` in an ordinary `flutter_test` widget
test. No browser, no emulator, no integration harness:

```dart
tester.view.physicalSize = const Size(400, 800);
tester.view.devicePixelRatio = 1.0;
addTearDown(tester.view.reset);

await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
await tester.pump();
await tester.pump(const Duration(milliseconds: 16)); // let onLoad/onGameResize settle

final gesture = await tester.startGesture(pieceCenter);
await tester.pump();
await gesture.moveTo(pieceCenter + dropDelta);
await tester.pump();
await gesture.up();
await tester.pump();

expect(logic.score, 1);
```

Recompute the layout formulas in the test for the fixed surface size to get the
start and drop coordinates. Duplicating that arithmetic is the point: if
someone changes the board layout without thinking, the test coordinates stop
landing where they should and the test fails loudly.

## Dart trap that bites in the tray

`List.generate(3, (_) => next())` reifies as `List<GameBlock>` even when assigned
to a `List<GameBlock?>` field. Dart's covariant lists allow the assignment, then
throw `type 'Null' is not a subtype of type 'GameBlock'` the moment a slot is
set to `null`. Wrap every such assignment: `List<GameBlock?>.from(...)` — and
check *every* assignment site, including `restart()`, not just the first one
that crashed.
