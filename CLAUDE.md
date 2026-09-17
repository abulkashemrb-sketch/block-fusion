# Block Fusion

A Block Blast-style casual puzzle game built with Flutter + Flame, shipped as a
PWA on Vercel with Supabase auth and score sync. Single codebase targets web
(primary) and Android (bonus).

## Commands

The Flutter SDK lives at `D:\dev\flutter` and is on the persistent user PATH.
Shells started before that PATH was set must use the full path
(`D:\dev\flutter\bin\flutter.bat`); a fresh terminal resolves `flutter` and
`dart` directly.

```bash
flutter analyze                 # must be clean before committing
flutter test                    # unit + widget tests
flutter build web --release     # output in build/web (gitignored)
```

To look at the running app locally: `flutter run -d chrome`. To serve an
existing release build instead: `python3 -m http.server 8766` from `build/web`.

## Architecture

Layers under `lib/`, deliberately separated so game rules stay testable without
Flutter or Flame in the way:

| Path | Holds |
|---|---|
| `models/` | Plain data: `GameGrid`, `Cell`, `BlockShape`, `GameBlock`. No Flutter imports. |
| `logic/` | Rules and state: `GameLogic` (placement, line clears, scoring, game over), `BlockGenerator`. `ChangeNotifier` only so HUD widgets can listen. |
| `game/` | Flame rendering and input: `BlockFusionGame`, `components/`. Draws from logic state; owns no rules. |
| `screens/` | Flutter screens: `HomeScreen`, `GameScreen` (hosts `GameWidget` + HUD overlays). |
| `theme/` | `AppTheme` — the single source of colors and text styles. |

Rule of thumb: if a change can be verified without pixels, it belongs in
`models/` or `logic/` and needs a unit test. Anything in `game/` that handles
input needs a widget test that drives a real gesture — see the `flame-game`
skill in `.claude/skills/`, which documents the coordinate-space and
drag-and-drop traps specific to this stack.

## Gameplay rules currently implemented

- 8x8 board, three pieces offered at a time, no rotation, tray refills when all
  three are used.
- Scoring: 1 point per placed cell; clearing N lines in one move scores
  `10 * N^2`, so multi-line combos are worth far more than sequential clears.
- Locked obstacle cells: block placement, count as filled for line completion,
  and lose one lock level per line clear that crosses them (two clears to open).
  Spawn at 20% per tray refill.
- Bomb piece (12% of generated pieces): placed on an empty cell, clears the 3x3
  around it, including locked cells outright.

## Hot reload

When editing `.dart` files under `lib/`, use the Dart MCP server to reload a
running app instead of restarting it by hand:

- Find running instances with `list_running_apps` / `dtd`.
- `hot_reload` after widget or method changes.
- `hot_restart` when `main()`, `initState`, or global/static state changed.
- Skip both for comment-only edits and for files outside `lib/`.

## Working agreement

- Explain the approach and get approval before writing code for a new phase or
  screen. The assignment is graded on incremental, AI-assisted development, so
  no one-shot generation of large chunks.
- Write explanations in Bengali script; keep code, paths, commands, and error
  text in their original form.
- Install new SDKs and tooling on the D drive — the C drive is nearly full.
- `.mcp.json` and `PROJECT_HANDOFF.md` are local working notes and are
  gitignored on purpose; they are not part of the shipped app.
