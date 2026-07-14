# Sonic Vault

The ultimate offline music player — your music, your covers, your lyrics, your rules.

[![Sonic Vault CI](https://github.com/Yuvraj-Sarathe/Sonic-Vault/actions/workflows/sonic-vault-ci.yml/badge.svg)](https://github.com/Yuvraj-Sarathe/Sonic-Vault/actions/workflows/sonic-vault-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Yuvraj-Sarathe/Sonic-Vault)](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases)
[![Website](https://img.shields.io/badge/website-sonicvault.vercel.app-blue)](https://sonicvault.vercel.app)

## Features

- **Offline-first** — plays music from your local storage. No streaming, no subscriptions.
- **Custom covers** — pick any image as album art for any song or playlist.
- **Playlists** — create, rename, reorder, and export playlists (M3U format).
- **Synchronized lyrics** — load LRC files for karaoke-style lyrics.
- **10-band equalizer** — built-in equalizer with presets.
- **Volume normalization** — per-song volume leveling for consistent playback.
- **Browse by genre / artist / album** — automatic organization of your library.

## Platforms

| Platform | Status | Download |
|----------|--------|----------|
| Windows  | ✅ Released | [Download ZIP](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) |
| Android  | ✅ Released | [Download APK](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) |
| Linux    | 🔧 CI builds | [Download tar.gz](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) |
| macOS    | 🔧 CI builds | [Download ZIP](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) |

## Project Structure

```
Sonic Vault/
├── lib/                          # Dart source code
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App shell, router, bottom nav, mini-player
│   ├── core/                     # Business logic, services, data layer
│   │   ├── audio/                # Audio playback engine (AudioService)
│   │   ├── constants/            # App, audio, and UI constants
│   │   ├── database/             # Drift ORM — tables, DAOs, migrations
│   │   ├── theme/                # Dark theme + accent color system
│   │   └── utils/                # Metadata reader, LRC parser, M3U exporter, etc.
│   ├── features/                 # Vertical feature slices
│   │   ├── browse/               # Browse by album / artist / genre
│   │   ├── cover_art/            # Custom cover art picker
│   │   ├── equalizer/            # 10-band equalizer UI
│   │   ├── library/              # Song library with search and sort
│   │   ├── lyrics/               # LRC synchronized lyrics display
│   │   ├── player/               # Now-playing screen
│   │   ├── playlists/            # Playlist CRUD + detail view
│   │   └── settings/             # Settings with accent picker
│   ├── providers/                # Riverpod state providers
│   └── shared/widgets/           # Reusable widgets (EmptyState, SongTile, etc.)
├── android/                      # Android platform files
│   ├── app/build.gradle.kts      # App-level Gradle config
│   ├── build.gradle.kts          # Root Gradle config
│   └── settings.gradle.kts       # Gradle settings
├── windows/                      # Windows desktop platform files
│   ├── runner/                   # C++ runner (main.cpp, flutter_window, etc.)
│   ├── flutter/                  # Flutter plugin registrations (generated)
│   └── CMakeLists.txt            # Project-level CMake config
├── linux/                        # Linux desktop platform files
│   ├── runner/                   # C++ runner (main.cc, my_application)
│   ├── flutter/                  # Generated plugin registrations
│   └── CMakeLists.txt
├── macos/                        # macOS platform files
│   ├── Runner/                   # Swift runner (AppDelegate, MainFlutterWindow)
│   └── Runner.xcodeproj/         # Xcode project
├── test/                         # Dart tests
│   ├── core/audio/               # AudioService unit tests
│   ├── core/database/daos/       # DAO tests with in-memory DB
│   ├── core/utils/               # File format utility tests
│   └── shared/widgets/           # Widget smoke tests
├── website/                      # Showcase website (Vercel-deployed)
│   ├── index.html                # Single-page marketing site
│   └── vercel.json               # Vercel deployment config
├── .github/workflows/            # CI/CD pipelines
│   ├── sonic-vault-ci.yml        # CI: analyze + build on push/PR
│   └── sonic-vault-release.yml   # Release: build + publish on tag
├── pubspec.yaml                  # Dart/Flutter package manifest
├── pubspec.lock                  # Locked dependency versions
├── analysis_options.yaml         # Dart linter rules
├── .gitignore                    # Git ignore rules
├── build_env.ps1                 # PowerShell script to set VS 2022 build env
├── build_windows.bat             # Debug Windows build helper
└── build_windows_release.bat     # Release Windows build helper
```

## Download

Grab the latest build from the [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) page.

| Platform | File | Instructions |
|----------|------|-------------|
| Windows | `SonicVault-windows.zip` | Extract and run `sonicvault.exe` |
| Android | `app-release.apk` | Enable "Install from unknown sources", open APK |
| Linux | `SonicVault-linux.tar.gz` | Extract and run the binary |
| macOS | `SonicVault-macos.zip` | Extract and open the `.app` bundle |

## Building from Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+
- Dart SDK 3.12+

### Setup
```bash
git clone https://github.com/Yuvraj-Sarathe/Sonic-Vault.git
cd Sonic-Vault
flutter pub get
```

### Run (debug)
```bash
flutter run -d windows   # Windows
flutter run -d android   # Android (device connected)
```

### Build (release)
```bash
flutter build windows --release   # Windows
flutter build apk --release       # Android APK
flutter build linux --release     # Linux
flutter build macos --release     # macOS
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.44 / Dart 3.12 |
| State Management | Riverpod (code generation) |
| Database | Drift (SQLite) |
| Audio Playback | just_audio |
| Audio Metadata | audio_metadata_reader |
| Navigation | go_router |
| Fonts | Google Fonts |
| File Management | file_picker, permission_handler |

## CI/CD

This project uses GitHub Actions for continuous integration and delivery:

- **CI Workflow** — runs on every push/PR to `main`: analyze → build Windows → build Linux → build Android → build macOS
- **Release Workflow** — runs on tag push (`v*`): builds all platforms → packages artifacts → creates a GitHub Release

## Website

The showcase website is at **[sonicvault.vercel.app](https://sonicvault.vercel.app)** (source in `website/`).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
