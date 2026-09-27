# AirDropConverter

A macOS menu bar utility that automatically detects HEIC files received via AirDrop and converts them to PNG or JPEG (WebP is offered only when the system has a compatible ImageIO encoder) with one click.

iPhoneからAirDropで送った画像（HEIC形式）を自動検出し、ワンクリックでPNG/JPEG（対応環境ではWebP）に変換するmacOSメニューバーアプリです。

## Why?

Photos taken on iPhone are saved in HEIC format. When you AirDrop them to your Mac, services like Google Slides, X (Twitter), and many web apps don't support HEIC — forcing you to manually open each file in Preview and export it as PNG.

AirDropConverter eliminates this friction entirely.

## Features

- **Auto-detection** — Waits for complete, stable HEIC/HEIF transfers and monitors `~/Downloads` in real-time and identifies AirDrop-received HEIC files using macOS quarantine attributes
- **One-click conversion** — Popup confirmation appears after received HEIC files finish transferring
- **Multiple formats** — Convert to PNG or JPEG (WebP is offered only when the system has a compatible ImageIO encoder)
- **Safe originals** — Optionally move originals to Trash only after successful conversion; existing outputs are never overwritten
- **Manual conversion** — Select HEIC/HEIF files from any folder through the menu
- **Responsive conversion** — Converts in the background and reports failures
- **Launch at Login** — Start automatically when you log in
- **Notifications** — Get notified when conversion completes
- **Bilingual** — English and Japanese (follows system language)
- **Lightweight** — Lives in the menu bar, no Dock icon, minimal resource usage

## Installation

1. Download `AirDropConverter-v1.0.2.zip` from [Releases](https://github.com/yuuki00682200/AirDropConverter/releases/latest)
2. Unzip and open `AirDropConverter.app`
3. The release app will ask to copy itself to `/Applications` — click **Move to Applications**
4. Allow Downloads access when prompted. Notifications are optional.

The v1.0.2 release is signed with Developer ID Application (MEMEMAKER, K.K.), notarized by Apple, and includes the notarization ticket.

## How It Works

```
AirDrop sends HEIC → ~/Downloads
       ↓
Periodic scan tracks new/replaced files and waits for stable size + modification time
       ↓
Reads com.apple.quarantine xattr → agent == "sharingd" → AirDrop confirmed
       ↓
ImageIO confirms the transfer is complete → Popup: "Convert to PNG?"
       ↓
Background ImageIO conversion → temporary file → validated output (no overwrite)
       ↓
Notification: "Conversion complete"
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Building from Source

1. Clone the repository
2. Open `AirDropConverter.xcodeproj` in Xcode 26.3+
3. Build and run (⌘R)

## License

MIT

## Development verification

Run `./scripts/test.sh` on macOS. The regression tests create real HEIC fixtures and verify output types, orientation, filename collisions, corrupt input handling, temporary-file cleanup, original preservation, and arrival tracking while files are growing or the UI is busy.

Create a local app and ZIP without a distribution certificate (ad-hoc signed, not notarized):

```sh
./scripts/build-local.sh
```

Debug builds do not offer installation into Applications. Pause state, output format, and the original-file option persist across launches. Files already present when monitoring starts (including when resumed) do not trigger prompts.

## Permissions and limitations

- Allow Downloads access when macOS asks. If denied, enable it under System Settings → Privacy & Security → Files and Folders, then pause and resume monitoring.
- Notifications are optional; denied notification permission does not prevent conversion.
- Auto-detection requires the quarantine agent to be `sharingd`. Files without that attribute can be converted manually.
- WebP decoding support does not imply encoding support. Standard systems may offer only PNG and JPEG; no working WebP encoder is bundled.
- Output files are saved next to the selected source. Only the primary still image is converted; HEIF sequences, depth maps and Live Photo video companions are not exported.
- Published v1.0.2 builds are Developer ID signed and Apple notarized. Local builds made with build-local.sh use ad-hoc signing and are not notarized.

Before publishing, verify on a physical Mac: single and batch AirDrop from iPhone, Downloads permission denial/recovery, notification permission, pause/resume, manual selection/cancel, move-to-Applications, Launch at Login after a real login, and both English/Japanese menus.

## Signed GitHub releases

After building with `./scripts/build-local.sh`, run:

```sh
./scripts/notarize-release.sh AirDropConverter
```

This requires a Developer ID Application signing identity with its private key, and a validated notarytool Keychain profile named `AirDropConverter`. Set `SIGNING_IDENTITY` to use another team's certificate. Credentials and private keys are never stored in the repository.

The script signs with Hardened Runtime and a secure timestamp, submits to Apple, requires Accepted status, staples and validates the ticket, checks Gatekeeper, and creates the versioned ZIP plus `build/SHA256SUMS.txt`. Publish only those verified artifacts.
