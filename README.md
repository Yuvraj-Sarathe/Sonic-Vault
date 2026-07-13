# Sonic Vault

The ultimate offline music player — your music, your covers, your lyrics, your rules.

## Features

- **Offline-first** — plays music from your local storage. No streaming, no subscriptions.
- **Smart metadata** — reads and displays ID3 tags, embedded cover art, and audio properties.
- **Custom covers** — pick any image as album art for any song or playlist.
- **Playlists** — create, rename, reorder, and export playlists (M3U format).
- **Lyrics** — load LRC files for synchronized karaoke-style lyrics.
- **Equalizer** — built-in 10-band equalizer with presets.
- **Volume normalization** — per-song volume leveling for consistent playback.
- **Browse by genre / artist / album** — automatic organization of your library.
- **Beautiful UI** — glassmorphism design with dynamic accent colors.

## Platforms

| Platform | Status |
|----------|--------|
| Windows | ✅ Released |
| Android | ✅ Released |
| Linux   | 🔧 CI builds |
| macOS   | 🔧 CI builds |

## Download

Grab the latest release from the [Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases) page.

### Windows
1. Download `SonicVault-windows.zip` from the latest release
2. Extract and run `sonicvault.exe`
3. Music folder: [Set your music directory](https://github.com/Yuvraj-Sarathe/Sonic-Vault/wiki) in Settings

### Android
1. Download `app-release.apk` from the latest release
2. Enable **Install from unknown sources** in your device settings
3. Open the APK file to install

## Building from source

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
flutter build windows --release   # Windows MSIX
flutter build apk --release       # Android APK
```

## Tech Stack

- **Framework:** Flutter 3.44 / Dart 3.12
- **State:** Riverpod (code generation)
- **Database:** Drift (SQLite)
- **Audio:** just_audio
- **Navigation:** go_router
- **Metadata:** audio_metadata_reader

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
