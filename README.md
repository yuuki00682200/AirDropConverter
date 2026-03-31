# AirDropConverter

A macOS menu bar utility that automatically detects HEIC files received via AirDrop and converts them to PNG, JPEG, or WebP with one click.

iPhoneからAirDropで送った画像（HEIC形式）を自動検出し、ワンクリックでPNG/JPEG/WebPに変換するmacOSメニューバーアプリです。

## Why?

Photos taken on iPhone are saved in HEIC format. When you AirDrop them to your Mac, services like Google Slides, X (Twitter), and many web apps don't support HEIC — forcing you to manually open each file in Preview and export it as PNG.

AirDropConverter eliminates this friction entirely.

## Features

- **Auto-detection** — Monitors `~/Downloads` in real-time and identifies AirDrop-received HEIC files using macOS quarantine attributes
- **One-click conversion** — Popup confirmation appears instantly when HEIC files arrive
- **Multiple formats** — Convert to PNG, JPEG, or WebP
- **Auto-delete** — Optionally remove the original HEIC file after conversion
- **Launch at Login** — Start automatically when you log in
- **Notifications** — Get notified when conversion completes
- **Bilingual** — English and Japanese (follows system language)
- **Lightweight** — Lives in the menu bar, no Dock icon, minimal resource usage

## Installation

1. Download `AirDropConverter-v1.0.0.zip` from [Releases](https://github.com/yuuki00682200/AirDropConverter/releases/latest)
2. Unzip and open `AirDropConverter.app`
3. The app will ask to move itself to `/Applications` — click **Move to Applications**
4. If macOS shows "can't be opened because Apple cannot check it for malicious software":
   - Go to **System Settings → Privacy & Security**
   - Click **Open Anyway**

## How It Works

```
AirDrop sends HEIC → ~/Downloads
       ↓
DispatchSource detects new file
       ↓
Reads com.apple.quarantine xattr → agent == "sharingd" → AirDrop confirmed
       ↓
Popup: "Convert to PNG?"
       ↓
ImageIO (CGImageSource/CGImageDestination) converts HEIC → PNG/JPEG/WebP
       ↓
Notification: "Conversion complete"
```

## Requirements

- macOS 14.0 (Sonoma) or later

## Building from Source

1. Clone the repository
2. Open `AirDropConverter.xcodeproj` in Xcode 15+
3. Build and run (⌘R)

## License

MIT
