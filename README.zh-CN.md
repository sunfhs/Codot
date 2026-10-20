<p align="center">
  <img src=".github/codex-usage-icon.png" width="112" height="112" alt="Codex Usage Compact app icon">
</p>
<h1 align="center">Codex Usage Compact</h1>
<p align="center"><strong>一眼查看 Codex 剩余额度与恢复时间</strong><br>Windows taskbar · macOS menu bar</p>
<p align="center">
  <a href="https://github.com/sunfhs/codex-usage-compact/releases/latest"><img src="https://img.shields.io/github/v/release/sunfhs/codex-usage-compact?style=flat-square" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/platforms-Windows%20%7C%20macOS-2878c8?style=flat-square" alt="Windows and macOS">
</p>
<p align="center">
  <a href="https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-windows-x64.zip">下载 Windows 版</a> ·
  <a href="https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-arm64.zip">Mac · Apple Silicon</a> ·
  <a href="https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-x64.zip">Mac · Intel</a>
</p>
<p align="center"><a href="README.md">English</a> · <a href="README.zh-CN.md">中文</a> · <a href="README.ja.md">日本語</a></p>

由 [sunfhs](https://github.com/sunfhs) 独立维护的个人项目。Windows 和 macOS 实现基于上游项目定制，来源署名与许可范围保留在 [NOTICE.md](NOTICE.md)。

Windows 任务栏 + macOS 菜单栏，一个项目、一个下载入口。两行数据常驻显示：**5 小时 / 每周剩余额度，以及对应恢复时间**。

```text
5h  ━━━━━━━───  55%  20:37
7d  ━━━━━━━━━─  93%  10/27
```

百分比表示剩余；时间按电脑本地时区显示，分别为 `HH:mm` 和 `MM/dd`。这只是排版示例，实际额度读取你本机已登录的账号。工具只显示额度，额度由服务端按时间恢复。

## 下载与安装

[最新发布版 / 所有平台下载](https://github.com/sunfhs/codex-usage-compact/releases/latest)

| 平台 | 下载包 | 安装 |
| --- | --- | --- |
| Windows 10/11 x64 | [下载 Windows 版](https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-windows-x64.zip) | 解压后双击 `install.cmd` |
| Mac（Apple Silicon）macOS 13+ | [下载 Mac · Apple Silicon 版](https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-arm64.zip) | 解压后双击 `Install.command` |
| Mac（Intel）macOS 13+ | [下载 Mac · Intel 版](https://github.com/sunfhs/codex-usage-compact/releases/download/v1.1.0/codex-usage-compact-v1.1.0-macos-x64.zip) | 解压后双击 `Install.command` |

先在本机 Codex / ChatGPT 登录。安装后自动配置开机或登录启动。Windows 安装到当前用户目录；Mac 安装到 `~/Applications/CodexVisual.app`，保留原来的偏好设置。已有 Mac App 会备份到 `~/Applications/CodexVisual-backups/`；如果旧的 `/Applications` App 没有移动权限，请先通过 Finder 备份后移走。

下载附有 SHA-256 校验文件。程序尚未进行公开代码签名；Mac 包使用 ad-hoc 签名，没有 Developer ID 公证，系统可能阻止首次运行。可按下方命令在自己的 Mac 构建；安装流程不要求关闭 Gatekeeper。

## 界面与语言

- **Windows**：原版宽高各 1/2、透明背景、任务栏垂直居中，无 GPT 图标，无“重置”尾字。[实拍与调整记录](docs/design.md)。
- **Mac**：原生菜单栏双行，22 pt 高，绿色进度条、透明背景，文字适配深浅色；macOS 空间不足时可能把它收进折叠区域。
- 默认每 60 秒读取一次。缺失窗口显示 `--`；Windows 旧数据会标 `*`，Mac 过期或历史数据的菜单栏显示 `--`。
- Windows：右键组件 → **语言** → 中文 / 日本語 / English。Mac：点击两行数据 → **语言 / 言語 / Language**，可跟随系统或手动选择，选择会保存。
- 三种语言均保持“剩余额度 + 本地恢复时间”的显示含义，切换语言不会改变额度计算。
- Mac 的“检查更新”打开本项目发布页，手动安装新包，避免上游更新覆盖定制效果。

![Windows 最终效果](docs/images/half-size-centered.png)

## 从源码构建

Windows（Rust stable + Visual Studio C++ Build Tools）：

```powershell
cargo test --release --locked
cargo build --release --locked
.\scripts\package.ps1
```

Mac（Xcode Command Line Tools，Swift 6+）：

```sh
cd macos
bash scripts/build_app.sh
bash scripts/test_quota_reader.sh
bash scripts/test_menubar.sh
bash scripts/install.command
```

GitHub Actions 在 Windows、Apple Silicon Mac 和 Intel Mac 上分别构建并验证。发布时三端安装包出现在同一个 Release 中。

## 项目与隐私

根目录 `src/` 是 Windows 原生 Rust/Win32 程序；`macos/` 是 Swift/AppKit 程序。合并保留了各自的界面与账号读取方式。

Windows 复用本机 Codex 登录信息读取官方服务；Mac 使用本机 `codex app-server`，保留本地日志回退。账号凭据、缓存、聊天记录均不随本项目发布。Mac 诊断输出可能含本机路径，公开前请检查。

Windows 来源：[upstream-ray/codex-usage-monitor](https://github.com/upstream-ray/codex-usage-monitor)；Mac 来源：[orangeshushu/CodexVisual](https://github.com/orangeshushu/CodexVisual)，合入 sunfhs 的菜单栏定制。原 Mac 仓库保留为历史备份。许可范围与来源见 [NOTICE.md](NOTICE.md)，Mac 原说明见 [macos/README.upstream.md](macos/README.upstream.md)。

本项目与 OpenAI 无隶属关系。详细的 Windows 安装、卸载说明见 [Windows 文档](docs/windows.md)；原 Mac 安装记录见 [macos/INSTALLATION.md](macos/INSTALLATION.md)。
