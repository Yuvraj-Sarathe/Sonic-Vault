# Security Policy

## Supported Versions

Sonic Vault is a fast-moving, independently developed project — only the **latest stable release** receives security fixes.

| Version | Supported |
|---------|-----------|
| Latest stable release ([Releases](https://github.com/Yuvraj-Sarathe/Sonic-Vault/releases/latest)) | ✅ Supported |
| Older releases | ❌ Not supported |

If you're on an older version, please update to the latest release before reporting an issue.

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security bugs** — that exposes the vulnerability to everyone before it can be fixed.

Instead, use GitHub's **private vulnerability reporting**:

1. Go to [https://github.com/Yuvraj-Sarathe/Sonic-Vault/security/advisories/new](https://github.com/Yuvraj-Sarathe/Sonic-Vault/security/advisories/new)
   (or: open the repository → **Security** tab → **Report a vulnerability**)
2. Fill in a description of the issue, including:
   - What the vulnerability is and where it occurs (file, function, platform)
   - Steps to reproduce or a proof of concept
   - Impact and any suggested fix, if you have one
3. Submit — it stays private until a fix is released.

> ⚠️ Public issues, PRs, or discussions describing security vulnerabilities will be closed and redirected to the private advisory process.

## What Happens Next

- **Acknowledgement** — we'll acknowledge your report within **7 days**.
- **Triage** — we'll assess severity and impact, and keep you updated on progress.
- **Fix & release** — we'll coordinate a fix and ship it in the next release.
- **Credit** — with your permission, you'll be credited in the release notes (or you can stay anonymous).

We ask that you wait until a fix is released before disclosing the vulnerability publicly.

## Scope

Sonic Vault is an **offline-first application**:

- ✅ **No accounts** — no sign-in, no user data stored on any server
- ✅ **No telemetry** — the app does not phone home, collect analytics, or track usage
- ✅ **No network endpoints** — playback and library features work fully offline; the only network activity is *optional* and user-initiated (e.g., checking GitHub Releases for updates via user-chosen tools like Obtainium, or downloading APKs/installers from GitHub Releases)

The security-relevant surface is therefore limited to local file/media handling and the packaged application itself (e.g., the Windows installer's certificate trust mechanism and the Android APK). If you find an issue in any dependency (Flutter, just_audio, Drift, etc.), please also report it to the upstream project.
