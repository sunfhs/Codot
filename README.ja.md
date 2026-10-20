<p align="center">
  <img src=".github/codex-usage-icon.png" width="112" height="112" alt="Codot app icon">
</p>
<h1 align="center">Codot</h1>
<p align="center"><strong>Codex の残り利用枠と回復時刻を、ひと目で。</strong><br>Windows taskbar · macOS menu bar</p>
<p align="center">
  <a href="https://github.com/sunfhs/codot/releases/latest"><img src="https://img.shields.io/github/v/release/sunfhs/codot?style=flat-square" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/platforms-Windows%20%7C%20macOS-2878c8?style=flat-square" alt="Windows and macOS">
</p>
<p align="center">
  <a href="https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-windows-x64.zip">Windows 版</a> ·
  <a href="https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-arm64.zip">Mac · Apple Silicon</a> ·
  <a href="https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-x64.zip">Mac · Intel</a>
</p>
<p align="center"><a href="README.md">English</a> · <a href="README.zh-CN.md">中文</a> · <a href="README.ja.md">日本語</a></p>

[sunfhs](https://github.com/sunfhs) が独立してメンテナンスする個人プロジェクトです。Windows と macOS の実装は既存プロジェクトを基に調整しており、出典とライセンスの範囲は [NOTICE.md](NOTICE.md) に記載しています。

**Windows のタスクバーと macOS のメニューバー**に Codex の利用枠を常時表示します。ソースコードとダウンロード先を一つにまとめました。

```text
5h  ━━━━━━━───  55%  20:37
7d  ━━━━━━━━━─  93%  10/27
```

数値は**残りの利用枠**です。回復時刻はパソコンの現地時間で、5時間枠は `HH:mm`、週間枠は `MM/dd` と表示します。上記は表示例です。実際にはこのパソコンでログイン中のアカウントから取得します。利用枠の回復はサービス側のスケジュールに従います。

## ダウンロードとインストール

[最新版 — 全プラットフォーム](https://github.com/sunfhs/codot/releases/latest)

| 対応環境 | ダウンロード | インストール |
| --- | --- | --- |
| Windows 10/11 x64 | [Windows 版をダウンロード](https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-windows-x64.zip) | 展開後 `install.cmd` をダブルクリック |
| Apple Silicon Mac、macOS 13以降 | [Mac · Apple Silicon 版](https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-arm64.zip) | 展開後 `Install.command` をダブルクリック |
| Intel Mac、macOS 13以降 | [Mac · Intel 版](https://github.com/sunfhs/codot/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-x64.zip) | 展開後 `Install.command` をダブルクリック |

先に同じパソコンの Codex / ChatGPT でログインしてください。インストーラーはログイン時の自動起動を設定します。Windows は現在のユーザーのフォルダーに、Mac は `~/Applications/CodexVisual.app` にインストールします。Mac の既存設定は引き継ぎ、旧アプリは `~/Applications/CodexVisual-backups/` に保存します。古い `/Applications` のアプリを権限の関係で移動できない場合は、Finder でバックアップしてから移動してください。

SHA-256 チェックサムを同梱しています。Windows 版は未署名です。Mac 版は ad-hoc 署名で、Developer ID による公証はありません。初回起動が制限される場合は、下記の方法でローカルビルドできます。Gatekeeper の無効化は不要です。

## 外観と言語

- Windows：元の幅・高さの1/2、透明背景、タスクバー中央に配置。GPT マークと回復時刻の後ろの文言を省略。[スクリーンショットと調整履歴](docs/design.md)。
- Mac：高さ22 ptのネイティブな2行表示、緑のバー、ライト・ダーク表示に対応する文字色。空きスペースが少ないと折りたたみ領域に入る場合があります。
- 既定の更新間隔は60秒。取得できない枠は `--`。Windows は古いデータに `*` を付け、Mac は期限切れ・過去の値を `--` と表示します。
- Windows は右クリック → **言語**、Mac は2行の数値をクリック → **言語**。中文 / 日本語 / English を選択すると保存されます。システム言語にも追従できます。
- 言語を切り替えても、残りの割合と現地時間による回復時刻は変わりません。
- Mac の「更新を確認」は統合後のリリースページを開きます。新しいパッケージを手動でインストールしてください。

![Windows の表示例](docs/images/half-size-centered.png)

## ビルドと検証

Windows：Rust stable と Visual Studio C++ Build Tools。

```powershell
cargo test --release --locked
cargo build --release --locked
.\scripts\package.ps1
```

Mac：Xcode Command Line Tools、Swift 6以降。

```sh
cd macos
bash scripts/build_app.sh
bash scripts/test_quota_reader.sh
bash scripts/test_menubar.sh
bash scripts/install.command
```

GitHub Actions で Windows、Apple Silicon、Intel をそれぞれビルド・検証し、同じリリースにパッケージを公開します。

## ソースとプライバシー

`src/` は Windows の Rust/Win32 アプリ、`macos/` は Swift/AppKit アプリです。各プラットフォームのネイティブ UI と取得処理を保持しています。Windows はローカルの Codex ログイン情報を使って公式サービスを読み取り、Mac はローカルの `codex app-server` とログを使います。ログイン情報・キャッシュ・会話履歴は公開しません。診断結果にはローカルパスが含まれる場合があるため、共有前に確認してください。

Windows の原作は [upstream-ray/codex-usage-monitor](https://github.com/upstream-ray/codex-usage-monitor)、Mac の原作は [orangeshushu/CodexVisual](https://github.com/orangeshushu/CodexVisual) です。Mac には sunfhs のメニューバー調整を統合しました。旧 Mac リポジトリは履歴のバックアップとして保持しています。出典とライセンスの適用範囲は [NOTICE.md](NOTICE.md)、原作の説明は [macos/README.upstream.md](macos/README.upstream.md) を参照してください。OpenAI とは関係のないコミュニティプロジェクトです。
