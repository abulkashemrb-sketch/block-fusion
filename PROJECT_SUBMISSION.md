# Block Fusion — Project Submission

**Module 3 Assignment: Flutter App / 2D Game with AI-Assisted Development**

A Block Blast-style casual puzzle game built with Flutter + Flame, shipped as
an installable PWA on Vercel and as per-ABI Android APKs from a single
codebase, with Google sign-in and score sync through Supabase.

---

## Submit Requirements

### Vercel Live Link

**https://block-fusion-three.vercel.app**

Public — no sign-in needed to open or play. Installable from the browser
("Add to Home screen") as a PWA.

### Zip file of your project

`block-fusion-submission.zip` — the full source, 118 tests, the SQL
migrations, the synthesised audio, and the APKs under `apk/`.

### Bonus: Android APK

Built with `flutter build apk --release --split-per-abi` and included in the
zip under `apk/`:

| File | Size | For |
|---|---|---|
| `app-arm64-v8a-release.apk` | 18.0 MB | Any modern phone — **use this one** |
| `app-armeabi-v7a-release.apk` | 15.5 MB | Older 32-bit devices |
| `app-x86_64-release.apk` | 19.4 MB | Emulators |

Installing may need "Install unknown apps" enabled for your file manager.

### Also public

**GitHub (public repository):**
https://github.com/abulkashemrb-sketch/block-fusion

---

## 1. Choose a Project

A 2D puzzle game built with **Flutter + Flame**.

**The core loop.** An 8x8 board. Three pieces are offered at a time, with no
rotation. Drag one onto the board; complete a row or a column and it clears.
Clearing several lines in one move scores far more than clearing them one at
a time (`10 x N²`), so combos are the thing worth playing for. The game ends
when none of the three pieces fits anywhere.

**Its own twists**, which the genre it is modelled on does not have:

- **Locked cells** block placement but still count towards completing a line.
  Each clear that crosses one takes a level off; two clears break it open.
- **Wildcard pieces** count as whatever colour the line around them is.
- **Same-colour bonus** — a cleared line whose coloured cells all match is
  worth double, which is what makes the wildcard worth saving.
- **Bomb pieces** drop on any cell, full or empty, and clear the 3x3 around
  them, including locked cells.

**On "clean, functional and visually appealing".** Blocks are drawn as
rounded cubes — a shaded base, a lit face, a gloss cap — over an indigo
gradient with a star field. Clearing a line bursts the blocks into shards,
floats the score up, and calls out combos, same-colour lines and new records.
Five sound effects and four vibration strengths, each with its own control in
settings, reachable from the menu and from inside a game. The board, tray and
score survive the app being closed mid-game.

Difficulty was tuned by measurement rather than feel: a simulation plays
hundreds of games with a deliberately mediocre player and reports how long
they last (`flutter test --run-skipped --tags simulation`). The first version
ran 90 moves on average with the unluckiest tenth over inside 34 — about a
minute. Weighting the piece draw against a crowded board and easing the
obstacles brought those to 155 and 52.

---

## 2. AI-Assisted Development

Built with Claude Code, **phase by phase rather than in one prompt**. The git
history is the evidence — **28 commits**, each one a phase with its reasoning
in the message:

| Phase | What it added |
|---|---|
| 0–1 | Project scaffold, then the core loop: grid, placement, line clears, scoring |
| 2 | Locked obstacle cells |
| 3 | Bomb power-up |
| 3.5 | Drag feel and fairness fixes (below) |
| 4 | Wildcard pieces and the same-colour bonus |
| 5 | The visual rebuild — cube blocks, gradient, star field, HUD |
| 6 | Supabase: Google sign-in, score sync, leaderboard |
| 7 | Clear animations, floating score, combo and record callouts |
| 8 | Sound and haptics |
| 9 | Saving the game in progress |
| 10 | Settings and an explanation of the pieces |
| 11 | Sync feedback, leaderboard paging, layout tests |

Each phase was described before it was written — what the screen had to do,
how it should behave, what could go wrong — and each ended with
`flutter analyze` clean and the test suite green before the next began.

**Quality gates:** `flutter analyze` is clean and **all 118 tests pass** in
about seven seconds. 33 source files, 17 test files. The tests are not only
unit tests of the rules: several drive real gestures through `GameWidget`,
and one checks the layout holds on five different screen shapes.

**Some of what the tests caught**, all of which had already been written and
reviewed:

- A dragged piece was drawn at tray scale but dropped at board scale, so it
  landed away from the cells the preview highlighted.
- `FlameAudio.play` returns a future, so a `try/catch` around it caught a
  missing audio channel but let a *refused* playback through as an unhandled
  rejection — which is exactly what a browser does before its first user
  gesture, on every single placement.
- A locked cell sitting where a cleared row and column crossed took two hits
  from one move, opening in half the intended time.
- On a 360-wide screen a four-cell-wide tray piece hung off the left edge.

---

## 3. Supabase Integration

### Supabase MCP used during development

The Supabase MCP server was used to create the project, apply migrations,
inspect the schema, and run `get_advisors` — which found something review had
not: both `SECURITY DEFINER` trigger functions were exposed as REST
endpoints, callable from the open internet without signing in. PostgreSQL
grants `EXECUTE` to `PUBLIC` by default and a trigger function inherits that
like any other.

`supabase/migrations/0002_revoke_trigger_function_execute.sql` is the fix,
and `supabase/migrations/README.md` writes up why it exists. The lesson is
worth more than the fix: run the advisor after every schema change rather
than trusting a migration because it reads as safe.

### Google Login through Supabase Authentication

Sign-in goes through Supabase's OAuth redirect rather than the `google_sign_in`
plugin, so web and Android run the same path. Android claims a custom scheme
for the return trip; the intent filter and the project's allowed-redirect list
have to agree, and the comment in each says so.

### Database sync

Two tables, deliberately:

- **`profiles`** — one row per player, holding the best score the game reads
  back on launch and the name and avatar a leaderboard needs.
- **`scores`** — one row per finished game, so a best score can always be
  recomputed from the record rather than trusted as a running total.

### User-specific data, properly associated

Row Level Security is enabled on both tables:

| Table | Read | Write |
|---|---|---|
| `profiles` | any signed-in player — this is what makes a leaderboard possible | only its owner (`auth.uid() = id`) |
| `scores` | only its owner | only its owner (`auth.uid() = user_id`) |

Two things are done in the database rather than the client, because a client
cannot be trusted with either:

- A trigger creates the profile row the moment a player first signs in, so
  the very first score always has somewhere to attach.
- A trigger raises `best_score` when a game is recorded, so nobody can claim
  a score they never played and a retried request cannot lower one that
  already stands.

This was verified, not assumed: reading `profiles` with the app's own public
key and no session returns an empty list, and an attempt to insert a score
against another player's id is refused with
`new row violates row-level security policy`.

---

## 4. Web & Deployment

### `flutter build web`

Built with `flutter build web --release`.

### GitHub public repository

https://github.com/abulkashemrb-sketch/block-fusion

### Vercel deployment

Deployed as a static site. `web/vercel.json` carries the cache headers and an
SPA rewrite: the build-named directories are pinned for a year, while the
entry points that keep their names across builds — `index.html`,
`main.dart.js`, the service worker, the manifest — are revalidated every
time, so a deploy is never served stale.

### PWA

The manifest carries the real name, description, theme colour and
portrait orientation; the icons are generated from the game's own palette,
including maskable variants; and the service worker comes out of the web
build, so the game is installable and runs offline.

`web/index.html` also carries a hook that lets a new build reach players who
already have an old one cached — Flutter's service worker otherwise waits for
every tab to close before taking over, which for a game people leave open can
be days.

---

## Running it yourself

```bash
flutter pub get
flutter analyze      # clean
flutter test         # 118 pass
flutter run -d chrome
```

The Supabase URL and publishable key are compiled in as defaults in
`lib/services/supabase_config.dart`, so it runs with no extra setup. That key
is meant to reach every client — Row Level Security, not its secrecy, is what
protects the data. **No secret is present anywhere in this archive.**

## Architecture

Layered so the game rules stay testable without Flutter or Flame in the way:

| Path | Holds |
|---|---|
| `lib/models/` | Plain data — `GameGrid`, `Cell`, `BlockShape`, `GameBlock`. No Flutter imports |
| `lib/logic/` | The rules — placement, clears, scoring, game over, piece generation |
| `lib/game/` | Flame rendering and input. Draws from logic state; owns no rules |
| `lib/screens/` | Home, game, leaderboard, settings |
| `lib/services/` | Supabase auth, score sync, local storage, sound and vibration |
| `lib/theme/` | The single source of colours and text styles |

The rule of thumb: anything verifiable without pixels lives in `models/` or
`logic/` and has a unit test; input handling in `game/` is covered by widget
tests that drive real gestures.

## Two things worth a look

The sound effects in `assets/audio/` are **synthesised, not downloaded** — FM
voices over ADSR envelopes, a filtered noise transient on each attack, and a
short delay tail. Nothing to license, about 340 KB for the set, and the
script that generates them explains each choice.

`.claude/skills/flame-game/` collects the traps this project actually hit —
the coordinate-space rule that decides where a dragged piece lands, and the
zero-sized `Stack` that renders a blank screen with no error anywhere.

## One known limitation

Google sign-in is still in Google's **"Testing"** mode, so only email
addresses on the project's test-user list can sign in; others see "Access
blocked". This does not affect playing — the whole game works signed out, and
the board and best score persist on the device. Only the leaderboard and
cross-device sync need an account. Any address can be added in a minute
(Google Cloud → Audience → Test users), up to 100.
