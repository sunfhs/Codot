# Codex Usage Compact

一个直接嵌在 **Windows 任务栏** 的 Codex 额度小组件。两行数据一直可见：5 小时剩余额度、每周剩余额度，以及对应的恢复时间。

**最终外观：原版 1/2 尺寸 · 透明背景 · 垂直居中 · 无 GPT 图标 · 无“重置”文字。**

![当前 Windows 任务栏实拍效果](docs/images/half-size-centered.png)

截图里的百分比是拍摄时的账号数据；软件会读取使用者自己的 Codex 账号，不包含演示额度。截图包含相邻的系统图标，便于看清大小与对齐关系。

## 下载和安装

前往 [最新发布版](https://github.com/sunfhs/codex-usage-compact/releases/latest)，下载 `codex-usage-compact-v1.0.0-windows-x64.zip`，解压到一个文件夹，然后双击 `install.cmd`。

安装器会校验 SHA-256，安装到当前用户目录，创建快捷方式，**启用开机自启动并在后台启动**。无需管理员权限。请先在本机 Codex 桌面版或 CLI 登录自己的 ChatGPT 账号。

也可在下载了 `install.ps1` 的文件夹中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

发布的程序尚未进行代码签名，Windows 可能提示来源未知。请核对下载地址为本项目的 GitHub Releases，并按自己的信任判断处理系统提示。

## 日常效果

```text
5h  ━━━━━━━───  55%  20:37
7d  ━━━━━━━━━─  93%  10/27
```

- `5h` 是 5 小时窗口；`7d` 是每周窗口。
- 百分比表示**剩余**额度；时间按电脑本地时区显示。
- 默认每 60 秒刷新，睡眠恢复或网络恢复后会重新读取。
- 没有某个窗口时显示 `--`；刷新失败时保留上次数据并标记 `*`，不会编造 100%。
- 鼠标悬停可查看数据更新时间；右键可调整刷新频率、语言、开机启动和外观；拖动左侧细线可调整横向位置。
- 托盘图标用于设置和隐藏/显示组件。任务栏上的两行数据本身无需点击即可查看。

## 为什么是这个尺寸

| 调整 | 最终选择与理由 |
| --- | --- |
| 信息入口 | 直接常驻任务栏，减少为看额度而点击的操作 |
| 视觉大小 | 原版宽高各 1/2；曾试过 1/3，阅读过小，最终放大到 1/2 |
| 垂直位置 | 在任务栏内居中，和系统图标栏对齐，避免贴住屏幕下沿 |
| 背景 | 去掉原来的黑色底板，让任务栏背景透过来 |
| 标识 | 隐藏两行之间的 GPT/OpenAI 图标 |
| 文案 | 去掉时间后面的“重置”，只保留 `HH:mm` 与 `MM/dd` |
| 色彩 | 绿色进度条和剩余百分比，较浅的时间文字；使用细的连续进度条 |
| 启动 | 安装后自动配置开机后台启动，默认显示中文 |

完整的外观演进截图和源码改动位置见 [外观记录](docs/design.md)。

## 系统与数据

支持 Windows 10/11 x64。这是 Windows 原生 Rust 程序，使用 Win32/GDI 绘制任务栏组件，支持 DPI 缩放；组件尺寸在原始 DPI 换算后再减半。本次最终效果实测于 3840×2160、200% 缩放的 Windows 桌面，其他 DPI 下的文字大小会不同。

软件复用本机 Codex 的登录信息，向对应的官方服务读取账号额度。它不会把对话内容、登录信息或用量上传到本项目仓库，也不要求手动粘贴令牌。GitHub 网络请求用于检查本项目的新版本；第三方服务监控继承自上游，默认关闭。

这是独立社区项目，与 OpenAI 无隶属关系。它只显示额度信息，不会消耗赠送的重置机会或绕过账号限制。

## 从源码构建

推荐在 Windows 上安装 Rust stable（MSVC 工具链）与 Visual Studio C++ Build Tools，然后运行：

```powershell
cargo test --release --locked
cargo build --release --locked
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

成品位于 `dist/`，包括可执行文件、校验值和可解压安装的 ZIP。GitHub Actions 会在发布 Release 时执行测试、编译并自动附上安装包。

## 卸载

在 Windows“设置 → 应用 → 已安装的应用”中卸载 **Codex Usage Compact**；或者运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Programs\CodexUsage\uninstall.ps1"
```

默认保留 `%APPDATA%\CodexUsage\settings.json`；添加 `-RemoveSettings` 可一并删除设置。安装目录和设置目录沿用上游，安装本版会替换同位置的原版，而不会同时运行两个组件。

## 来源与许可

本项目基于 [upstream-ray/codex-usage-monitor v1.10.0](https://github.com/upstream-ray/codex-usage-monitor/tree/v1.10.0) 定制，保留上游完整业务源码和 MIT 许可。保留了 Codex 查询、多显示器、网络恢复、托盘设置、错误标记等上游能力，本版主要调整外观与安装默认值。

上游提交：`c2a53e7441b93015821c989f2ff07dfcd137476b`。详细归属见 [NOTICE](NOTICE.md)、[LICENSE](LICENSE) 和 [图标来源许可](src/icons/providers/LICENSE)。
