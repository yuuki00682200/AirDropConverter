# AirDropConverter landing page

The page is served from the repository-root `index.html`. CSS, JavaScript, favicon, and the approved logo are in `website/`. No package manager, framework, build command, or environment variables are required.

## ロリポップ！デプロイナウ

GitHub連携で次の設定を選びます。

- Repository: `yuuki00682200/AirDropConverter`
- Branch: `main`
- Framework: **静的サイト / static**

GitHubから取得したリポジトリのルートに `index.html` があるため、ルートURLでLPが表示されます。ビルドは不要です。接続後はmainへのpushで自動デプロイされます。

公式手順:
- https://deploy.lolipop.jp/docs/frameworks/static
- https://deploy.lolipop.jp/docs/quickstart/github

This repository also contains the macOS app source. The hosting provider has no deployment-only file exclusion setting; the app source is already public on GitHub. Do not add credentials, private keys, or local build products to tracked files.

## Local preview

Run from the repository root:

```sh
python3 -m http.server 4173 --bind 127.0.0.1
```

Open http://127.0.0.1:4173/. The EN / 日本語 button switches visible copy, document language, title, and description. Download buttons always link to GitHub's latest release.

The site uses local assets and system fonts. It does not upload images, set cookies, or include tracking scripts.
