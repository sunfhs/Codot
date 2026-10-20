# Codex Quota Menu Bar · macOS 定制版

基于 [orangeshushu/CodexVisual](https://github.com/orangeshushu/CodexVisual) 的个人 Mac 定制版，保留原项目源码和提交历史。[原版说明](README.upstream.md)

菜单栏直接显示两行：

```text
5h  [绿色进度条]  55%  20:37
7d  [绿色进度条]  93%  10/27
```

上面是排版示例。运行时从本机已登录的 Codex 读取真实账号额度。

- 百分比与进度条表示**剩余**，恢复时间使用 Mac 本地时区。
- 5 小时恢复时间为 `HH:mm`，每周恢复日期为 `MM/dd`。
- 固定两行，绿色进度条，文字适配深浅色菜单栏，不显示名称或图标。
- 每 60 秒刷新，使用 LaunchAgent 在登录后启动。
- 复用 ChatGPT/Codex 内置的 `codex app-server`；无需手动复制令牌。
- 缺失、过期或仅有历史缓存时显示 `--`，不猜测数值。
- 保持默认菜单栏位置；macOS 可能将其收进双箭头的折叠区域。这是本次最终确认的布局。

## 获取 App 和完整备份

[下载 Release](https://github.com/sunfhs/codex-quota-menubar/releases/latest)。其中包含：

- `CodexVisual-macOS-arm64.zip`：本机验证过的 Apple Silicon App、登录自启配置和说明。
- `CodexVisual-original-8c9a2e1.tar.gz`：未经修改的原版源码。
- `CodexVisual-original-app.zip`：原版 App 备份。
- `SHA256SUMS.txt`：下载文件的校验值。

当前预编译 App 使用 ad-hoc 签名，没有 Developer ID 公证。其他 Mac 可以从源码本地编译；不需要关闭 Gatekeeper。

## 在 Mac 上安装同一套配置

先登录本机 ChatGPT/Codex。使用预编译包时，在解压后的目录执行以下安装命令；使用源码时，先安装 Xcode Command Line Tools，运行 `./scripts/build_app.sh`，再将第一条命令中的 `CodexVisual.app` 改为 `build/CodexVisual.app`。

以下按首次安装到 `/Applications` 编写；如果已有运行中的 CodexVisual，先退出它，已有 App 请先另行备份。

```sh
ditto --norsrc --noextattr CodexVisual.app /Applications/CodexVisual.app
codesign --verify --deep --strict /Applications/CodexVisual.app
defaults write com.orangeshushu.CodexVisual refreshMode -string everySixtySeconds
defaults write com.orangeshushu.CodexVisual menuBarDisplayMode -string bars
mkdir -p "$HOME/Library/LaunchAgents"
cp Resources/com.orangeshushu.CodexVisual.plist "$HOME/Library/LaunchAgents/"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.orangeshushu.CodexVisual.plist"
```

启动后只显示菜单栏。再次从 Applications 打开 App 可进入原项目的控制窗口。

## 验证、原版与恢复

```sh
./scripts/build_app.sh
bash scripts/test_quota_reader.sh
bash scripts/test_menubar.sh
```

原版源码固定在 Git 标签 `upstream-original-1.0.21`，对应提交 `8c9a2e119501200c8bba5b5a2a4afba76786adca`。当前定制版只针对 macOS；继承的 Windows 源码没有验证。

详细的本机验证记录和停用/恢复方法见 [INSTALLATION.md](INSTALLATION.md)。GitHub 不包含本机登录文件、账号额度缓存或真实账号截图。

原项目的“检查更新”会安装上游版本，可能覆盖本地定制。上游发布工作流也需要原作者的签名配置，本仓库的预编译包由本地构建上传。
