> 此文件保留合并前在原 Mac 上的安装与验证记录。1.1.0 的当前安装步骤以根目录三语言 README 为准，源码历史与原版备份仍在旧仓库。
> Historical record from the original Mac; use the root README for v1.1.0 instructions.
> 統合前の Mac の記録です。現行の手順はルートの README を参照してください。

# 本机 Codex 额度监控

安装位置：`/Applications/CodexVisual.app`。

基于 orangeshushu/CodexVisual，原版提交：`8c9a2e119501200c8bba5b5a2a4afba76786adca`。

## 当前配置

- 菜单栏固定两行：`5h [绿色条] 百分比 HH:mm`、`7d [绿色条] 百分比 MM/dd`，宽 174 pt、高 22 pt。
- 百分比和进度条均表示剩余。时间使用 Mac 当前本地时区。
- 文字随菜单栏深浅色绘制；菜单栏不显示名称或图标。
- 每 60 秒启动一次刷新；账号读取耗时会使两次完成时间相隔约 61 秒。
- 直接调用本机 ChatGPT/Codex 内置的 `codex app-server`，复用已登录账号，不读取或复制登录令牌。
- 按返回的实际窗口显示，不按套餐名称隐藏窗口。缺失、过期或只有历史缓存时，菜单栏显示 `--`。
- 登录自启：`~/Library/LaunchAgents/com.orangeshushu.CodexVisual.plist`。正常退出后不强制重开，异常退出时由 launchd 恢复。
- 启动仅显示菜单栏；从 Applications 再次打开时显示原项目的控制窗口。
- 按用户偏好恢复原先的菜单栏位置，撤回 `CodexQuota` 的固定位置设置。macOS 可能将其收进双箭头的系统溢出区域。

## 源码和备份

当前文件夹为修改后源码，Git 保留原版提交，并上传至私有仓库 `sunfhs/codex-quota-menubar`。原版源码标签为 `upstream-original-1.0.21`。

相邻 `../backups/` 中保留：

- `CodexVisual-original-8c9a2e1.tar.gz`：未经修改的原版源码。
- `CodexVisual-original.app`：原版可运行 App（仅适配本机 Swift 6.0 构建声明）。
- `CodexVisual-original-app.zip`：不含 Finder 扩展元数据的原版 App 备份，已解压验证签名。
- `CodexVisual-local.patch`：本地源码差异；新增文件直接保留在当前源码中。

GitHub Release 提供同名原版源码和 App 备份，供其他 Mac 下载恢复。本机的缓存、真实账号读数和实际账号界面截图不上传。

本机只有 Swift 6.0.3，已将 Package.swift 的工具版本从 6.1 降为 6.0，无新增依赖。
应用使用本机 ad-hoc 签名，没有修改系统安全设置。

## 已执行验证

- Release 构建、安装后的签名校验、构建与安装二进制 SHA-256 一致。
- `bash scripts/test_quota_reader.sh`：账号优先、剩余额度、Pro 返回窗口、缺失或错误窗口。
- `bash scripts/test_menubar.sh`：22 pt 双行、缺失/过期/历史数据、东京/洛杉矶时区、同一张菜单栏图像的深浅色文字适配。
- 安装后运行并读取当前账号；观察到无人操作的自动刷新，间隔 60.908 秒。
- 安装后空闲 CPU 为 0.0%；已修复最初外观监听引发的重复重绘。
- launchd 服务已加载并运行，RunAtLoad 为 true。
- 已检查实际控制窗口中的当前账号数据。菜单栏深浅色渲染图和刷新记录保留在 `build/verification/`。

渲染图使用固定测试数值，仅用于版式和颜色验证；实际账号读数见 `build/verification/account-read.txt`。

没有为验证而注销或重启 Mac；登录自启已通过 LaunchAgent 配置和加载启动验证。

## 重建和恢复

在当前源码目录执行 `./scripts/build_app.sh` 重建。
安装复制应使用 `ditto --norsrc --noextattr`，避免 iCloud 的 Finder 元数据破坏签名校验。

若要停用登录自启：

```sh
launchctl bootout "gui/$(id -u)/com.orangeshushu.CodexVisual"
mv "$HOME/Library/LaunchAgents/com.orangeshushu.CodexVisual.plist" "$HOME/Library/LaunchAgents/com.orangeshushu.CodexVisual.plist.disabled"
```

若要恢复原版，先停用上述服务，然后在当前源码目录执行：

```sh
ditto --norsrc --noextattr ../backups/CodexVisual-original.app /Applications/CodexVisual.app
open /Applications/CodexVisual.app
```

原项目的“检查更新”是手动功能；安装上游新版会覆盖本地排版修改，需要重新应用源码变更。
