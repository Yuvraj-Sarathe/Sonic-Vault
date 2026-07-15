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
- **🎲 Play Random** — shuffle button that plays a random song from your queue or entire library.
- **⌨️ Keyboard shortcuts** — control playback without touching the mouse.

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Space** | Play / Pause |
| **N** | Next track |
| **P** | Previous track |
| **→** | Skip forward 5 seconds |
| **←** | Skip back 5 seconds |

Shortcuts work globally — from any screen in the app.

## Platforms

| Platform | Status | Download |
|----------|--------|----------|
| Windows  | ✅ Released | [Download ZIP](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |
| Android  | ✅ Released | [Download APK](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |
| Linux    | 🔧 CI builds | [Download tar.gz](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |
| macOS    | 🔧 CI builds | [Download ZIP](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |

## Download & Install

Grab the latest build from the [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) page.

### Windows

**Option A — Portable (no install)**
1. Download `SonicVault-windows-v*.zip`
2. Extract the folder
3. Run `sonicvault.exe`

**Option B — Signed Installer (recommended)**
1. Download `SonicVault-Setup-*.exe`
2. Run it as **Administrator** (right-click → Run as administrator)
3. The installer will trust the app certificate, add desktop shortcuts, and launch Sonic Vault
4. Windows will show zero security warnings after the first install

> ⚠️ The installer requires admin rights once to install the app certificate. After that, the app runs without admin privileges.

### Android

1. Download `SonicVault-android-v*.apk`
2. On your phone, enable **Install from unknown sources** (Settings → Security → Install unknown apps)
3. Open the APK file and tap Install

### Linux

1. Download `SonicVault-linux-v*.tar.gz`
2. Extract: `tar -xzf SonicVault-linux-*.tar.gz`
3. Run: `./sonicvault`

### macOS

1. Download `SonicVault-macos-v*.zip`
2. Extract and open the `.app` bundle
3. If macOS shows "unidentified developer", go to **Settings → Privacy & Security** and click **Open Anyway**

## Building from Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+
- Dart SDK 3.12+
- **Windows**: [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) with "Desktop development with C++"
- **Linux**: `clang`, `cmake`, `gtk3-dev`, `ninja-build`
- **macOS**: Xcode 15+
- **Android**: Android Studio (or just `flutter doctor --android-licenses`)

### Setup
```bash
git clone https://github.com/Yuvraj-Sarathe/Sonic-Vault.git
cd Sonic-Vault
flutter pub get
```

### Run (debug)
```bash
flutter run -d windows       # Windows
flutter run -d android       # Android (device connected)
flutter run -d linux         # Linux
flutter run -d macos         # macOS
```

### Build (release)
```bash
flutter build windows --release   # → build/windows/x64/runner/Release/sonicvault.exe
flutter build apk --release       # → build/app/outputs/flutter-apk/app-release.apk
flutter build linux --release     # → build/linux/x64/release/bundle/
flutter build macos --release     # → build/macos/Build/Products/Release/
```

### Windows Installer (requires Inno Setup)

After building the Windows release:

```bash
# Using Inno Setup Compiler GUI
# Open installer/installer.iss → Build → Compile

# Or command line:
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\installer.iss
```

This produces a signed `.exe` installer that handles certificate trust automatically.

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
├── windows/                      # Windows desktop platform files
├── linux/                        # Linux desktop platform files
├── macos/                        # macOS platform files
├── test/                         # Dart tests
├── website/                      # Showcase website (Vercel-deployed)
├── cert/                         # Code signing certificates
├── installer/                    # Inno Setup installer script
├── .github/workflows/            # CI/CD pipelines
└── pubspec.yaml                  # Dart/Flutter package manifest
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
