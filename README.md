# Block Fusion

A Block Blast-style casual puzzle game built with **Flutter + Flame**, shipped as
a PWA on Vercel and as an Android APK from the same codebase.

**Play it: https://block-fusion-three.vercel.app** (installable as a PWA)

Submitting or marking this? `PROJECT_SUBMISSION.md` maps the assignment's
requirements to where each one is met.

Drag one of three offered pieces onto an 8x8 board. Fill a row or a column and it
clears. Clear several lines in one move and the combo multiplies. Two twists on
the genre carry the scoring: **locked obstacle cells** that take two clears to
break open, and **wildcard pieces** that let you finish a line in a single color
for double points.

## Gameplay rules

| Rule | Detail |
|---|---|
| Board | 8x8, three pieces offered at a time, no rotation |
| Tray refill | When all three pieces are used |
| Placement score | 1 point per cell placed |
| Line clear | `10 x N²` for N lines cleared in one move |
| Same-color bonus | A cleared line whose colored cells all match is worth double |
| Locked cell | Blocks placement, counts as filled for line completion, loses one lock level per clear that crosses it (two clears to open). Spawns at 20% per tray refill |
| Bomb piece | 12% of pieces. Drops on **any** cell and clears the 3x3 around it, locked cells included |
| Wildcard piece | 8% of pieces. A colorless cell that counts as whatever color the line around it is |
| Game over | No piece in the tray fits anywhere. A tray is never dealt without at least one playable piece |

## Architecture

Layers under `lib/`, separated so the game rules stay testable without Flutter or
Flame in the way:

| Path | Holds |
|---|---|
| `models/` | Plain data: `GameGrid`, `Cell`, `BlockShape`, `GameBlock`. No Flutter imports |
| `logic/` | Rules and state: `GameLogic` (placement, clears, scoring, game over), `BlockGenerator`. `ChangeNotifier` only so HUD widgets can listen |
| `game/` | Flame rendering and input: `BlockFusionGame`, `components/`. Draws from logic state; owns no rules |
| `screens/` | Flutter screens: `HomeScreen`, `GameScreen` (hosts `GameWidget` + HUD overlays) |
| `theme/` | `AppTheme` — the single source of colors and text styles |

The rule of thumb: anything verifiable without pixels lives in `models/` or
`logic/` and has a unit test. Input handling in `game/` is covered by widget
tests that drive real gestures through `GameWidget`.

## Running it

Requires the Flutter SDK (stable channel).

```bash
flutter pub get
flutter analyze                 # must be clean
flutter test                    # unit + widget tests
flutter run -d chrome           # play it locally
```

### Builds

```bash
flutter build web --release             # output in build/web
flutter build apk --release --split-per-abi   # per-ABI APKs in build/app/outputs/flutter-apk
```

## Web deployment

`build/web` is a static site. `web/vercel.json` is copied into the build output
and sets the cache headers plus an SPA rewrite, so the directory can be deployed
to Vercel as-is:

```bash
flutter build web --release
rm -rf build/web/.vercel      # see below
vercel deploy build/web --prod
```

That `rm` is not superstition. `vercel deploy build/web` writes its project
link into `build/web/.vercel`, and `flutter build web` updates that
directory rather than replacing it — so the link survives rebuilds and
silently re-points later deploys at whatever project it happens to name.

Files under `assets/`, `canvaskit/` and `icons/` are pinned for a year; the
entry points that keep their names across builds (`index.html`,
`main.dart.js`, the service worker, the manifest) are revalidated every time,
so a deploy is never served stale. The PWA manifest, icons and service worker
come out of the web build — the app is installable from the browser.

## Notes for the curious

Two things in here were harder than they look, and both are written up in
`.claude/skills/flame-game/`:

- A dragged piece is drawn at **board** cell size, not tray size. Tray pieces are
  smaller so three fit across, and drawing the dragged piece at that smaller size
  makes it miss the cells the preview highlights.
- A `Stack` whose children are all positioned collapses to zero size and paints
  nothing, with no error anywhere. `StackFit.expand` is not optional on the game
  screen.
