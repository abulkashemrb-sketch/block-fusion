# Block Fusion — submission

A Block Blast-style 2D puzzle game built with Flutter + Flame, shipped as a
PWA on Vercel and as per-ABI Android APKs from one codebase.

## Links

| | |
|---|---|
| **Live (PWA)** | https://block-fusion-three.vercel.app |
| **GitHub (public)** | https://github.com/abulkashemrb-sketch/block-fusion |

## What is in the archive

| Path | Contents |
|---|---|
| `lib/` | App source, layered `models` / `logic` / `game` / `screens` / `services` |
| `test/` | 118 unit and widget tests |
| `supabase/migrations/` | The SQL that creates the tables, RLS policies and triggers |
| `assets/audio/` | Five sound effects, synthesised rather than sourced |
| `android/`, `web/` | Platform projects, including the PWA manifest and icons |
| `apk/` | Release APKs from `flutter build apk --release --split-per-abi` |

`apk/app-arm64-v8a-release.apk` is the one for a modern phone. Installing it
may need "Install unknown apps" enabled for your file manager.

## Requirements, and where each one is met

**1. Flutter app / 2D game.** An 8x8 board, three pieces at a time, line
clears with a combo multiplier, plus two twists of its own: locked obstacle
cells that take two clears to break, and wildcard pieces that let a line be
finished in a single colour for double points. Clears burst into shards, the
score floats up, combos and records are called out, and the game has sound
and vibration with a level control for each. The board, tray and score
survive being closed mid-game.

**2. Step-by-step AI-assisted development.** The git history is the
evidence: twenty-six commits, each a phase with its reasoning in the
message, not one generated dump. `flutter analyze` is clean and all 118
tests pass, including gesture-driven widget tests and a layout test across
five screen shapes.

**3. Supabase.** Google sign-in through Supabase Auth; a `profiles` row per
player holding their best score, and a `scores` row per finished game. Row
Level Security is on for both — profiles are readable by any signed-in
player so a leaderboard is possible, while a player's individual games stay
private to them. Two database triggers do the work a client cannot be
trusted with: one creates the profile the moment a player first signs in,
the other raises `best_score` when a game is recorded, so nobody can claim
a score they never played.

The Supabase MCP server was used throughout — creating the project, applying
migrations, and running `get_advisors`, which found that both
`SECURITY DEFINER` trigger functions were exposed as REST endpoints callable
without signing in. `supabase/migrations/README.md` has that story;
migration `0002` is the fix.

**4. Web, GitHub, Vercel, PWA.** Built with `flutter build web --release`
and deployed to Vercel as a static site; `web/vercel.json` carries the cache
headers and the SPA rewrite. The manifest, icons and service worker make it
installable, and `web/index.html` carries a hook that lets a new build reach
players who already have an old one cached.

**Bonus.** APKs built with `--split-per-abi`, under `apk/`.

## Running it yourself

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

The Supabase URL and publishable key are compiled in as defaults in
`lib/services/supabase_config.dart`, so it runs without extra setup. That key
is meant to be public — Row Level Security, not its secrecy, protects the
data. No secret is present anywhere in this archive.

Signed out, the whole game is playable and the board, tray and best score
persist on the device; only the leaderboard and cross-device sync need an
account, and every call to the backend degrades quietly rather than failing
the app.

## Two things worth a look

The sound effects in `assets/audio/` are synthesised, not downloaded — FM
voices over ADSR envelopes, with a noise transient on the attack and a short
delay tail. Nothing to license, and about 340 KB for the set.

`.claude/skills/flame-game/` collects the traps this project actually hit:
the coordinate-space rule that decides where a dragged piece lands, the
zero-sized `Stack` that renders a blank screen with no error anywhere, and
why the drag tests recompute the layout arithmetic by hand.
