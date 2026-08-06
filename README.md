<p align="center">
  <img src="website/favicon-512.png" alt="Sonic Vault logo" width="120">
</p>

# 🎵 Sonic Vault

**Your music. Your covers. Your lyrics. Your rules.**

Sonic Vault is a free, open-source, **offline-first** music player for Windows, Android, Linux, and macOS (iOS in progress). It plays your local library — no streaming, no subscriptions, no accounts — and puts *you* in charge of covers, lyrics, playlists, and playback. Point it at your music folder, press play, and your library belongs to you again.

**Current version: [v1.3.8](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest)**

[![Sonic Vault CI](https://github.com/Yuvraj-Sarathe/Sonic-Vault/actions/workflows/sonic-vault-ci.yml/badge.svg)](https://github.com/Yuvraj-Sarathe/Sonic-Vault/actions/workflows/sonic-vault-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Yuvraj-Sarathe/Sonic-Vault)](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases)
[![Website](https://img.shields.io/badge/website-github.io-blue)](https://yuvraj-sarathe.github.io/Sonic-Vault/)
[![Get it on F-Droid](https://fdroid.gitlab.io/artwork/badge/get-it-on.png)](https://yuvraj-sarathe.github.io/Sonic-Vault/repo)
[![Get it on Obtainium](https://raw.githubusercontent.com/ImranR98/Obtainium/main/assets/graphics/badge_obtainium.png)](https://app.obtainium.imranr.dev/add?r=https://github.com/Yuvraj-Sarathe/Sonic-Vault)

> 🚨 **TESTERS NEEDED ASAP — Linux, macOS & iOS!**
> The Linux and macOS builds work and pass CI, but real-world testing is what turns "it builds" into "it works" — and iOS is still being actively worked on. If you're on one of those platforms, grab a build, break things, and tell us about it. See the dedicated testers-wanted issues for a checklist: [Linux](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues/1) · [macOS](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues/2) · [iOS](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues/3). Or check the [platform status table](#platforms) below.
>
> ⚠️ The self-hosted F-Droid repository (`/repo`) serves Android builds only. Sonic Vault is **not** on the official F-Droid.org store — the badge above points to our own repository.

---

## ✨ Features

| Feature | What it does |
|---------|--------------|
| 🎵 **Offline-first playback** | Plays music from your local storage. No streaming, no subscriptions, no accounts. |
| 🖼️ **Custom cover art** | Pick any image as album art — for individual songs *and* playlists. |
| 📋 **Playlists** | Create and rename playlists, styled with custom covers. M3U export is drafted and on the workbench. |
| 💬 **Synchronized lyrics** | Drop an `.lrc` file next to your music for karaoke-style, time-synced lyrics. |
| 🎲 **Play Random** | One tap plays a random song from your queue — or from your entire library when the queue is empty. |
| 🗂️ **Browse by genre / artist / album** | Your library is automatically organized from embedded metadata. |
| 🔀 **Shuffle & repeat** | Shuffle on/off and repeat modes: off / all / one. |
| ⌨️ **Global keyboard shortcuts** | Control playback from any screen in the app without touching the mouse. |

> 🎛️ **On the workbench** — the 10-band equalizer (31 Hz – 16 kHz, 7 presets) has its UI and presets drafted in the app but the DSP isn't wired up yet; per-song **volume normalization** is on the roadmap; **M3U playlist export** is drafted but not wired into the UI. Everything above the line ships today.

### ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Space** | Play / Pause |
| **N** | Next track |
| **P** | Previous track |
| **→** | Skip forward 5 seconds |
| **←** | Skip back 5 seconds |

Shortcuts work globally — from any screen in the app.

## Platforms

<div align="center">

| Platform | Status | Get it |
|----------|--------|--------|
| Windows  | ✅ Released | [Download](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |
| Android  | ✅ Released | [Download APK](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) |
| Linux    | ✅ Working — needs testers | [Build from source](#building-from-source) |
| macOS    | ✅ Working — needs testers | [Build from source](#building-from-source) |
| iOS      | 🛠️ Being worked on — testers wanted | [Build from source](#building-from-source) |

</div>

> 🧪 **Testers wanted!** We're actively working on **macOS, iOS & Linux** — they build and run, but real-world testing is what turns "it builds" into "it works". If you're on one of those platforms, give it a try and **feel free to open an issue** for anything you hit (or anything you love): [Open an issue](https://github.com/Yuvraj-Sarathe/Sonic-Vault/issues/new).
>
> ⚠️ GitHub Releases currently publish **Windows & Android** binaries only — once macOS, iOS & Linux get enough tester feedback, they'll get official releases too.

## Download & Install

Grab the latest build from the [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) page (Windows & Android). For macOS, iOS & Linux, see [Building from Source](#building-from-source) below.

### Windows

**Option A — Signed Installer (recommended, auto-trusts the app)**
1. Download `SonicVault-Setup-*.exe` from [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest)
2. Right-click the installer → **Run as administrator** (required once to install the certificate)
3. The installer will trust the app certificate, create shortcuts, and launch Sonic Vault
4. After first install, the app runs **without admin rights** and shows zero security warnings

> ⚠️ The installer requires admin rights once to install the self-signed certificate into Windows Trusted Root. After that, the app runs normally without admin privileges.

**Option B — Portable (no install, no admin)**
1. Download `SonicVault-windows-v*.zip` from [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest) — the portable ZIP was shipped through v1.2.0; if the latest release only carries the installer, use **Option A** instead
2. Extract the folder (right-click → Extract All)
3. Run `sonicvault.exe`
4. If Windows SmartScreen appears, click **More info** → **Run anyway**

### Android

**Option A — Obtainium (recommended: automatic updates)**

[Obtainium](https://obtainium.imranr.dev) is an open-source "app store without the store" — it tracks the GitHub repository and updates apps in place when a new release is published.

1. Install Obtainium from its [GitHub releases](https://github.com/ImranR98/Obtainium/releases) (it isn't on the Play Store)
2. Add Sonic Vault by tapping the button below (it pre-fills the app source), or manually: open Obtainium → **Add App** → paste the source URL **`https://github.com/Yuvraj-Sarathe/Sonic-Vault`** → tap **Add**
3. Obtainium reads the GitHub Releases page, finds `app-release.apk`, and lists Sonic Vault with its current version. Keep that repo link in your account — it's what Obtainium checks for updates, and it can auto-update the app whenever a new version is published.

[![Get it on Obtainium](https://img.shields.io/badge/Get%20it%20on-Obtainium-107C41?style=for-the-badge&logo=android&logoColor=white)](https://app.obtainium.imranr.dev/add?r=https://github.com/Yuvraj-Sarathe/Sonic-Vault)

**Option B — F-Droid client (self-hosted repo)**

Sonic Vault runs its own F-Droid repository, hosted on GitHub Pages and rebuilt automatically on every release:

1. In any F-Droid client (F-Droid, Droidify, Neo Store): **Settings → Repositories → Add repository**
2. Paste the repository URL: `https://yuvraj-sarathe.github.io/Sonic-Vault/repo`
3. Sonic Vault appears in the app list with the current version; updates arrive automatically when a new release rebuilds the repo

**Option C — Manual APK install**

1. Download `app-release.apk` from [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest)
2. On your phone, enable **Install from unknown sources** (Settings → Security → Install unknown apps → select your file manager/browser)
3. Open the APK file (via file manager or browser downloads) and tap **Install**
4. If Google Play Protect warns, tap **Install anyway** (this is an open-source app, not on Play Store)

> ✅ Minimum Android 7.0 (API 24). No special permissions beyond storage access for your music folder.
>
> ⚠️ **Redmi / Xiaomi (MIUI / HyperOS) users:** sorry — just give up. Xiaomi's aggressive permission management blocks the folder & media access Sonic Vault needs, so on Redmi the app just can't get its features to work. On **Samsung and most other devices it works fine** — and if you're on one of those and something's off, open an issue and we'll fix it.

### Linux

1. Linux binaries aren't published in current Releases — build from source (see [Building from Source](#building-from-source)); the bundle lands in `build/linux/x64/release/bundle/`
2. Run the app:
   ```bash
   ./build/linux/x64/release/bundle/sonicvault
   ```
3. If it won't run, make it executable:
   ```bash
   chmod +x build/linux/x64/release/bundle/sonicvault
   ./build/linux/x64/release/bundle/sonicvault
   ```

**Dependencies:** Requires GTK 3.24+ (standard on Ubuntu 20.04+, Fedora 35+, Arch, etc.). For AppImage/Flatpak, build from source.

### macOS

1. macOS builds aren't published in current Releases — build from source (see [Building from Source](#building-from-source)); the app lands in `build/macos/Build/Products/Release/`
2. Open the `Runner.app` bundle: `open build/macos/Build/Products/Release/Runner.app`
3. **If macOS blocks it** (unidentified developer):
   - Go to **System Settings → Privacy & Security**
   - Scroll down to "Security" → click **Open Anyway** next to the Sonic Vault entry
   - Or run in Terminal: `xattr -d com.apple.quarantine build/macos/Build/Products/Release/Runner.app`

> 📱 Requires macOS 10.15+ (Catalina). CI builds run on Apple Silicon, so the app is built for the host architecture. No notarization — Gatekeeper will prompt once.

## Building from Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; the repo pins Dart SDK ^3.12.2)
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
├── website/                      # Showcase website (GitHub Pages)
├── cert/                         # Code signing certificates
├── installer/                    # Inno Setup installer script
├── .github/workflows/            # CI/CD pipelines
└── pubspec.yaml                  # Dart/Flutter package manifest
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (repo pins Dart ^3.12.2) |
| State Management | Riverpod |
| Database | Drift (SQLite) |
| Audio Playback | just_audio |
| Audio Metadata | audio_metadata_reader |
| Navigation | go_router |
| Fonts | Google Fonts |
| File Management | file_picker, permission_handler |

## CI/CD

This project uses GitHub Actions for continuous integration and delivery:

- **CI Workflow** — runs on every push/PR to `main`: analyze → build Windows → build Linux → build Android → build macOS
- **Release Workflow** — runs on tag push (`v*`): builds Windows & Android → packages artifacts → creates a GitHub Release
- **F-Droid Repo Workflow** — runs on every published release: downloads the new APK, rebuilds the self-hosted F-Droid repository index, and redeploys it (together with the website) to GitHub Pages at `https://yuvraj-sarathe.github.io/Sonic-Vault/repo`

## Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to set up a dev environment, code style, commit conventions, and the PR/release process
- **[SECURITY.md](SECURITY.md)** — supported versions and how to report a vulnerability privately
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — the standards we expect from everyone in this community

## Website

The showcase website is at **[yuvraj-sarathe.github.io/Sonic-Vault](https://yuvraj-sarathe.github.io/Sonic-Vault/)** (source in `website/`, hosted on GitHub Pages together with the F-Droid repository).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
