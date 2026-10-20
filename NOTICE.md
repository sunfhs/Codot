# Attribution

Codex Usage Compact is a visual customization of `upstream-ray/codex-usage-monitor` v1.10.0, based on commit `c2a53e7441b93015821c989f2ff07dfcd137476b`.

Upstream: https://github.com/upstream-ray/codex-usage-monitor

The upstream MIT license and its copyright notice are preserved verbatim in LICENSE. The upstream package credits the original work to Code Zeno Pty Ltd / Craig Constable and subsequent modifications to Ray. Included provider artwork retains its existing attribution and license in src/icons/providers/.

This repository's changes were prepared for sunfhs: compact half-size rendering, transparent taskbar background, vertical centering, hiding the Codex provider mark, removing the Chinese reset suffix, Chinese/minute-refresh defaults, automatic startup installation, documentation, screenshots and packaging. These customizations are distributed under the same MIT license.

Codex, ChatGPT and OpenAI names belong to their respective owners. This project is not affiliated with or endorsed by OpenAI.

## macOS component

The `macos/` app is imported from sunfhs/codex-quota-menubar commit `59fbe995da4861fab8142f43026b713716dece16`, which customizes orangeshushu/CodexVisual commit `8c9a2e119501200c8bba5b5a2a4afba76786adca` (v1.0.21). Original source and attribution remain in macos/README.upstream.md and macos/INSTALLATION.md. The previous repository retains its commit history and original release backups.

Upstream: https://github.com/orangeshushu/CodexVisual

The imported macOS snapshot does not include a LICENSE file. Its code and artwork retain their original copyright; the root MIT license applies to the Windows component and does not relicense the imported macOS source or grant additional rights to it. Check upstream permissions before further redistribution. The integration adds Japanese localization, unified release links, tests and packaging without publishing local credentials, caches or account screenshots.
