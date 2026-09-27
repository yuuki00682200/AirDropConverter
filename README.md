# AirDropConverter

[日本語](#日本語) · [English](#english)

サービスLPは [index.html](index.html)、デプロイ設定は [website/README.md](website/README.md) にあります。

The landing page is in [index.html](index.html); hosting instructions are in [website/README.md](website/README.md).

## 日本語

iPhoneからAirDropで受信したHEIC/HEIF画像を自動検出し、PNG・JPEGへ変換するmacOSメニューバーアプリです。

[最新版をダウンロード](https://github.com/yuuki00682200/AirDropConverter/releases/latest)

### 主な機能

- **自動検出**：ダウンロードフォルダを監視し、AirDrop由来の画像の受信完了とファイルの安定を待って変換を案内します。
- **まとめて変換**：受信した複数の画像をまとめて変換できます。変換はバックグラウンドで実行します。
- **手動変換**：メニューの「HEICファイルを変換…」から、任意のフォルダの画像を選択できます。
- **出力形式**：PNG・JPEGに対応。WebPはmacOSのImageIOが書き出しに対応している環境のみ表示します。
- **元画像を保護**：「変換後にHEICを削除」をオンにすると、変換成功後に元画像をゴミ箱へ移動します。失敗した画像や変換中に変更された元画像は保持します。
- **上書き防止**：同名の出力がある場合は連番を付けます。画像の向きを反映して保存します。
- **設定の保存**：監視の停止状態、出力形式、元画像を削除する設定を次回起動時も保持します。
- **ログイン時に起動**・**変換完了通知**・**日本語／英語表示**に対応。Dockアイコンを表示せずメニューバーに常駐します。

### インストール

1. [GitHub Releases](https://github.com/yuuki00682200/AirDropConverter/releases/latest)から最新版のZIP（v1.0.3では `AirDropConverter-v1.0.3.zip`）をダウンロードします。
2. 解凍し、`AirDropConverter.app`をApplicationsフォルダへコピーして起動します。別の場所から起動すると、コピーを案内します。
3. macOSから要求されたら、ダウンロードフォルダへのアクセスを許可してください。通知の許可は任意です。
4. メニューバーから出力形式や「変換後にHEICを削除」を設定します。

**v1.0.3はDeveloper ID Application（MEMEMAKER, K.K.）で署名し、Appleの公証を取得済みです。公証チケットも添付しています。**

### 動作環境

- macOS 14.0（Sonoma）以降
- Apple SiliconまたはIntel Mac（配布アプリはUniversal）

### 使い方と制限

AirDropで画像を受信すると、受信完了後に変換確認が表示されます。出力は元画像と同じフォルダに保存します。

- 自動検出にはquarantine属性の送信元が `sharingd` である必要があります。属性のない画像は手動変換してください。
- 監視開始時や停止から再開した時点ですでに存在する画像は、自動変換の対象になりません。
- WebPの読み込み対応と書き出し対応は異なります。WebPエンコーダーは同梱していません。
- HEIFの主画像のみ変換します。連続画像、深度情報、Live Photoの動画は出力しません。
- フォルダへのアクセスを拒否した場合は、システム設定 → プライバシーとセキュリティ → ファイルとフォルダで許可し、監視を停止・再開してください。
- 通知を許可しなくても変換できます。
- iPhoneからの実際のAirDrop、再ログイン後の自動起動、Intel実機での起動は未検証です。

### 開発・検証・配布

ソースを取得し、`AirDropConverter.xcodeproj`をXcode 26.3以降で開いてビルド・実行してください。DebugビルドではApplicationsへのコピー案内を表示しません。

```sh
# 実HEIC画像を使用する回帰テスト
./scripts/test.sh

# Apple Silicon・Intel両対応のローカルビルド
./scripts/build-local.sh

# Developer ID署名・Apple公証・配布ZIP作成
./scripts/notarize-release.sh AirDropConverter
```

テストは、画像形式・向き・同名ファイル保護・元画像保持・破損入力・一時ファイル清掃、AirDrop属性判定、受信安定待ち・処理中の受信保持・同名再受信を検証します。

`build-local.sh`はアドホック署名の未公証アプリと `build/AirDropConverter-local.zip` を作成します。

`notarize-release.sh`には秘密鍵付きのDeveloper ID Application証明書と、認証済みのnotarytoolキーチェーンプロファイルが必要です。引数はプロファイル名です。別チームの証明書は環境変数 `SIGNING_IDENTITY` で指定できます。認証情報と秘密鍵はリポジトリに保存しません。

配布スクリプトはHardened Runtimeとタイムスタンプを有効にして署名し、公証のAcceptedを確認、公証チケット添付・検証・Gatekeeper検証を実施します。成果物は `build/AirDropConverter-v1.0.3.zip` と `build/SHA256SUMS.txt` です。

公開前には実機で、単一／複数画像のAirDrop、フォルダ権限の拒否と回復、通知、監視停止と再開、手動選択とキャンセル、Applicationsへのコピー、再ログイン後の自動起動、両言語のメニューを確認してください。

### ライセンス

[MIT](LICENSE)

---

## English

A macOS menu bar app that automatically detects HEIC/HEIF images received from an iPhone via AirDrop and converts them to PNG or JPEG.

[Download the latest release](https://github.com/yuuki00682200/AirDropConverter/releases/latest)

### Features

- **Automatic detection**: Monitors Downloads and waits for complete, stable AirDrop transfers before offering conversion.
- **Batch conversion**: Converts multiple received images in the background.
- **Manual conversion**: Choose images from any folder using “Convert HEIC Files…” in the menu.
- **Output formats**: PNG and JPEG. WebP is offered only when the system's ImageIO supports encoding it.
- **Safe originals**: Enable “Delete HEIC after conversion” to move originals to Trash after successful conversion. Failed inputs and originals changed during conversion are kept.
- **No overwrites**: Existing outputs are protected with numbered filenames. Image orientation is baked into the output pixels.
- **Persistent settings**: Pause state, output format, and the original-file option survive app restarts.
- **Launch at Login**, **completion notifications**, and **English/Japanese menus**. Runs in the menu bar without a Dock icon.

### Installation

1. Download the latest ZIP from [GitHub Releases](https://github.com/yuuki00682200/AirDropConverter/releases/latest) (`AirDropConverter-v1.0.3.zip` for v1.0.3).
2. Unzip, copy `AirDropConverter.app` to Applications, and open it. When launched from elsewhere, the release app offers to copy itself.
3. Allow Downloads access when prompted. Notifications are optional.
4. Select an output format and configure “Delete HEIC after conversion” from the menu.

**v1.0.3 is signed with Developer ID Application (MEMEMAKER, K.K.), notarized by Apple, and includes the notarization ticket.**

### Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac; distributed as a Universal app

### Usage and limitations

After receiving an image via AirDrop, confirm conversion in the prompt. Outputs are saved next to the source images.

- Automatic detection requires the quarantine agent to be `sharingd`. Use manual conversion for images without that attribute.
- Files already present when monitoring starts or resumes do not trigger automatic prompts.
- WebP decoding support does not imply encoding support. No WebP encoder is bundled.
- Only the primary HEIF image is converted. Image sequences, depth maps, and Live Photo video companions are not exported.
- If Downloads access was denied, enable it in System Settings → Privacy & Security → Files and Folders, then pause and resume monitoring.
- Denying notifications does not prevent conversion.
- Physical iPhone AirDrop transfers, Launch at Login after a real login, and execution on an Intel Mac have not been verified.

### Development, testing, and distribution

Clone the repository and open `AirDropConverter.xcodeproj` in Xcode 26.3 or later to build and run. Debug builds do not offer installation into Applications.

```sh
# Regression tests using real HEIC images
./scripts/test.sh

# Local Universal build for Apple Silicon and Intel
./scripts/build-local.sh

# Developer ID signing, Apple notarization, and distribution ZIP
./scripts/notarize-release.sh AirDropConverter
```

Tests cover output types, orientation, filename collisions, original preservation, corrupt input, temporary-file cleanup, AirDrop quarantine classification, stable-transfer detection, arrivals during a busy UI, and reused filenames.

`build-local.sh` creates an ad-hoc signed, non-notarized app and `build/AirDropConverter-local.zip`.

`notarize-release.sh` requires a Developer ID Application signing identity with its private key and a validated notarytool Keychain profile. The argument is the profile name. Set `SIGNING_IDENTITY` to use another team's certificate. Credentials and private keys are never stored in the repository.

The distribution script signs with Hardened Runtime and a secure timestamp, requires Accepted notarization status, staples and validates the ticket, and checks Gatekeeper. Outputs are `build/AirDropConverter-v1.0.3.zip` and `build/SHA256SUMS.txt`.

Before publishing, verify on a physical Mac: single and batch AirDrop, Downloads permission denial/recovery, notifications, pause/resume, manual selection/cancel, copying to Applications, Launch at Login after a real login, and menus in both languages.

### License

[MIT](LICENSE)
