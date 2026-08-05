# Contributing to Sonic Vault

First off — thanks for being here! 🎵 Sonic Vault is an open-source, offline-first music player, and every contributor makes it better. Whether you're fixing a bug, polishing the UI, writing tests, or improving docs — you're welcome.

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Quick Start (5 minutes)

1. **Fork** the repo on GitHub: [Yuvraj-Sarathe/Sonic-Vault](https://github.com/Yuvraj-Sarathe/Sonic-Vault)
2. **Clone** your fork:
   ```bash
   git clone https://github.com/<your-username>/Sonic-Vault.git
   cd Sonic-Vault
   ```
3. **Install dependencies** and make sure Flutter is happy:
   ```bash
   flutter pub get
   flutter doctor
   ```
4. **Run the app** on your platform:
   ```bash
   flutter run -d windows   # or: -d android / -d linux / -d macos
   ```

Requires Flutter 3.44+ / Dart 3.12+ (see [README → Building from Source](README.md#building-from-source) for platform prerequisites).

## How the repo is organized

Sonic Vault follows a **features / shared / core** split:

- `lib/core/` — platform-agnostic business logic: the audio engine (`audio/`), Drift database (`database/`), constants, theme, and utilities (metadata reader, LRC parser, M3U exporter, media scanner)
- `lib/features/` — one directory per vertical slice: `browse`, `cover_art`, `equalizer`, `library`, `lyrics`, `player`, `playlists`, `settings`
- `lib/providers/` — hand-written Riverpod providers (Drift is the only codegen in the repo)
- `lib/shared/` — reusable widgets and cross-feature helpers
- `lib/main.dart` / `lib/app.dart` — entry point and app shell (router, bottom nav, mini-player, global shortcuts)
- `test/` — mirrors `lib/` so every module has a home for its tests

Key libraries: **Riverpod** (`flutter_riverpod`) for state, **Drift** (SQLite, the one codegen in the repo via `build_runner`) for persistence, **go_router** for navigation, **just_audio** for playback.

## Before you code

- **Open an issue first.** Feature ideas, bug reports, and design discussions all start on the [issue tracker](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues) — it lets everyone align before code is written.
- Comment on the issue saying you'd like to work on it, so work isn't duplicated.
- Small fixes (typos, one-line bugs) don't need an issue — just send the PR.

## Branching & PRs

- All PRs target **`main`**.
- Name your branch after what it does: `fix/eq-panel-crash`, `feat/volume-normalization`, `docs/readme-touchup`.
- Keep PRs **small and focused** — one logical change per PR is easier to review and merge.
- CI runs on every push/PR: `flutter analyze` plus release builds for **Windows, Linux, Android, and macOS**. Your PR must leave CI green.
- Before pushing, run the local checks:
  ```bash
  flutter analyze && flutter test
  ```
  (CI currently runs analysis and builds but not the test suite — that's on your plate locally, and we'd love a PR that adds a test job to CI!)
- Mention which issue your PR closes, e.g. `Closes #42`.

## Commit style

Keep commits consistent with the existing history — one line, lowercase, with a scope prefix:

```
fix: correct seek position after track change
ci: cache Flutter SDK between CI runs
readme: document Obtainium setup
website: add favicon set
metadata: fix F-Droid SourceCode field name
test: cover m3u exporter edge cases
```

Pattern: `type: short imperative description`. Common types: `fix:`, `feat:`, `ci:`, `test:`, `readme:`, `website:`, `metadata:`, `docs:`, `refactor:`. Don't worry about being exhaustive — match the style, keep the message under ~72 characters.

## Code style

- **Format:** `dart format .` — Flutter's standard formatter is the law.
- **Lint:** `flutter analyze` must pass with zero issues (`flutter_lints` ruleset).
- Prefer small, focused widgets; use Riverpod providers for shared state instead of prop-drilling or `setState` hoisting.
- When you change database tables or providers, regenerate the code:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- Write code for the next reader — comments explain *why*, not *what*.

## Adding tests

- New logic should come with tests. The `test/` directory mirrors `lib/`, so:
  - `lib/core/utils/m3u_exporter.dart` → `test/core/utils/m3u_exporter_test.dart`
  - `lib/core/database/daos/song_dao.dart` → `test/core/database/daos/song_dao_test.dart`
- Run the whole suite or a single file:
  ```bash
  flutter test                 # everything
  flutter test test/core/utils # everything under a directory
  flutter test test/core/utils/m3u_exporter_test.dart  # one file
  ```
- `mockito` is in the dev dependencies, though existing tests mostly lean on real services — see `test/core/audio/audio_service_test.dart` (uses `AudioService.testing()`) for an example.

## Release process (maintainers)

Releases are triggered by tags — no manual artifact juggling:

1. Bump the version in `pubspec.yaml` (e.g. `version: 1.3.8`)
2. Commit and push to `main`
3. Tag and push: `git tag v1.3.8 && git push origin v1.3.8`
4. The **Release workflow** builds the Windows installer (Inno Setup, signed with the certificate in `cert/`) and the Android APK, then creates a GitHub Release with auto-generated notes
5. The **F-Droid workflow** picks up the published release automatically, rebuilds the self-hosted repository index, and redeploys it with the website to GitHub Pages (`https://yuvraj-sarathe.github.io/Sonic-Vault/repo`)
6. Announce the release on the [discussions](https://github.com/Yuvraj-Sarathe/Sonic-Vault/discussions) or issues

## Reporting bugs & security issues

- **Bugs & feature requests:** open an [issue](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues/new) — include steps to reproduce, expected vs. actual behavior, and your platform/version.
- **Security vulnerabilities:** do **not** open a public issue — see [SECURITY.md](SECURITY.md) for the private reporting process.

Thanks for helping make Sonic Vault better — happy hacking! 🎧
