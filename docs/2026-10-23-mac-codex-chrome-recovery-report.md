# 2026-10-23 办公 Mac Codex / Chrome 恢复报告

## 结果与适用范围

本次通过同一局域网内的 SSH 修复办公 Mac 的 Codex Chrome 集成。恢复后，Mac 本机 Codex 使用真实 Chrome 插件完成了连接、读取标签页、新建页面、导航、DOM、截图、链接点击、返回和测试页关闭。原有 API/provider 配置节与本次修改前备份一致。

此报告记录“2026-10-23 实际验证的设备与软件组合”。它不保证其他版本、其他网络或整机故障可以原样恢复。当前工作状态仍依赖 Windows 代理和 SSH 转发。

## 设备与软件清单

以下硬件、系统和应用字段于 2026-10-23 通过 SSH 只读查询确认。未采集或发布设备序列号、硬件 UUID、密码及密钥。

| 项目 | 本次值 |
| --- | --- |
| 设备用途 / 名称 | 办公 Mac / `una的MacBook Pro` |
| LocalHostName | `unadeMacBook-Pro` |
| 硬件型号 | `MacBookPro11,4` |
| CPU | Intel Core i7-4770HQ @ 2.20 GHz，8 个逻辑 CPU |
| 架构 / 内存 | `x86_64` / 16 GiB |
| macOS | `12.7.6`，构建 `21H1320` |
| 本地用户 / SSH | `apple` / `ssh apple@10.1.1.211` |
| Codex 应用目录 | `/Applications/ChatGPT.app` |
| Bundle ID / 可执行文件 | `com.openai.codex` / `ChatGPT` |
| 应用版本 / 构建 | `26.727.51351` / `6119` |
| 应用声明的最低系统 | macOS `12.0` |
| 应用自带 CLI | `/Applications/ChatGPT.app/Contents/Resources/codex` |
| CLI 版本 | `0.146.0-alpha.9.2` |
| 应用自带 Node | `/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node`，`v24.14.0` |
| Chrome 插件 | `chrome@openai-bundled`，资源版本 `26.727.51351` |
| Chrome 扩展 ID | `hehggadaopoacecdllhhajmbjkdcmajg` |
| 检测到的已启用 Chrome profile | `Profile 4`；用户资料内容未复制 |
| 最后检查中存在的扩展版本目录 | `1.26.1005.11759_0`、`1.26.1015.10801_0`、`1.26.1020.11845_0`；目录存在不等于同时运行 |
| 认证方式 | 原有 API/provider 配置；实际凭据未发布 |

私网 IP、用户目录、profile 和应用目录未来都可能改变，恢复前要重新核对。

## 本地文件位置

| 用途 | 本次路径 |
| --- | --- |
| Codex 用户目录 | `/Users/apple/.codex` |
| 原始配置 | `/Users/apple/.codex/config.toml`，仅本机保存 |
| 原生扩展清单 | `/Users/apple/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.openai.codexextension.json` |
| Chrome 插件缓存 | `/Users/apple/.codex/plugins/cache/openai-bundled/chrome/26.727.51351` |
| `latest` 别名 | `/Users/apple/.codex/plugins/cache/openai-bundled/chrome/latest` → `26.727.51351` |
| 本机通信程序 | `chrome/latest/extension-host/macos/x64/ChatGPT for Chrome`，相对于插件缓存根目录 |
| 应用内置 Chrome 插件源 | `/Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled/plugins/chrome` |
| 正常运行时市场来源 | `/Users/apple/.codex/.tmp/bundled-marketplaces/openai-bundled` |
| 运行时市场清单 | 上述目录下 `.agents/plugins/marketplace.json` |
| 应用日志 | `/Users/apple/Library/Logs/com.openai.codex/`，原始日志留本机 |
| 修改前备份 | `/Users/apple/.codex/repair-backups/chrome-20261023-035751` |
| Windows 辅助恢复目录 | `E:\CodexBackups\office-mac-chrome-20261023` |
| 本次 Windows SSH 密钥路径 | `C:\Users\zhang\.ssh\codex-office-mac-repair`，密钥内容未复制 |

Mac 备份目录实际包含 `config.toml`、`config.after-uninstall.toml`、`config.before-marketplace-fix.toml`、`chrome-26.727.51351/`，以及修复后验证 JSON 和截图。配置备份不是可直接公开的模板，也不应无条件覆盖用户后来新增的设置。

## 历史回退线索

会话记录中的先前恢复涉及从 `26.730.61309` 回退至 `26.727.51351`。本次修复开始时，Mac 已运行后者，因此本次没有重新替换整个应用。

本次只读确认 `/Applications/ChatGPT.app.backup-26.730.61309d` 目录存在，末尾的 `d` 属于真实目录名。这个目录保存的是较新版本的历史副本；本次没有验证它可成功启动、可修复插件，或可作为回退到工作版本的安装包。不要把它当成已验证的正常基线覆盖当前应用。

如未来确需更换应用，先确认系统、CPU 架构、应用来源、版本与签名，再在外部终端、应用完全退出后执行。不要根据本报告盲目删除当前应用。应用完整安装包、Keychain 和 Chrome 内部数据不在本仓库内。

## 故障表现

用户报告 Chrome 插件无法连接或操作。Chrome 扩展可以显示已安装，插件详情中的按钮也曾显示 `Try now`，但本机 native host 清单缺失，无法据此确认插件可用。

应用中曾出现浏览器“被组织禁用或所在地区不可用”、插件“Unavailable in this context”，以及搜索 Chrome 无结果。该界面文案描述功能当时不可用，不单独证明用户存在真实组织禁用策略。

## 已确认的两个阻断因素

### 1. 功能服务网络不可达

Mac 对 `ab.chatgpt.com` 的 DNS 结果出现干扰；直连请求失败。通过可用代理下的 DoH 查询得到真实目标地址后，再以 `--resolve` 保持 TLS 校验直连，仍收到 `Connection reset by peer`。因此只改公共 DNS 不能恢复本次环境。

Windows 已有代理监听在 `127.0.0.1:10808`。通过 SSH 反向转发，将该监听映射到 Mac 的 `127.0.0.1:18081`，再以应用专属参数启动 Codex：

```text
--proxy-server=socks5://127.0.0.1:18081
```

恢复网络后，应用运行时市场清单实际包含 `browser`、`chrome`、`latex`、`visualize`。这证明当时应用已允许 Chrome 进入正常安装流程。没有通过修改功能门控、认证类型或应用签名文件实现恢复。

测试功能服务某个 GET 路径返回 HTTP 403，仅说明该 HTTPS 服务可达；正常初始化使用其他请求条件，不能把这个 403 单独视为功能初始化成功。

### 2. 同名插件市场来源冲突

旧登记指向：

```text
/Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled
```

当前版本启动时要登记的来源是：

```text
/Users/apple/.codex/.tmp/bundled-marketplaces/openai-bundled
```

应用日志明确报告：

```text
marketplace 'openai-bundled' is already added from a different source;
remove it before adding this source
```

该冲突使自动安装流程在登记市场阶段返回。只还原插件缓存或原始 Chrome 配置块不能解决：应用在功能不可用时，曾以 `not_in_bundled_marketplace_plugin_names` 为原因自动卸载 Chrome。不能把随后缺失的 native host 当作独立根因，反复手工写清单。

## 实际执行的修复步骤

1. 使用 `apple@10.1.1.211` 和本次专用 SSH 密钥连接。Windows 默认 SSH 配置存在权限问题，因此所有本次 SSH 命令使用 `-F none` 绕过该配置，没有修改用户默认配置的所有权。
2. 检查当前应用版本、插件、扩展、配置相关字段与日志。备份配置和 Chrome 插件到 Mac 的 `repair-backups/chrome-20261023-035751`。
3. 通过应用设置引导安装与检查 Chrome 组件。发现“浏览器扩展安装”和“Codex 本机通信组件安装”是不同环节，前者成功不足以完成后者。
4. 为跨 SSH 操作应用设置，用户在 macOS 辅助功能中明确授权了 `/usr/libexec/sshd-keygen-wrapper` 和 `/usr/bin/osascript`。这属于远程操作设置界面的权限，不是所有 Chrome 恢复场景的必需步骤。
5. 诊断并恢复功能服务网络：Windows 现有代理 → SSH `-R 127.0.0.1:18081:127.0.0.1:10808` → Mac Codex 应用专属 SOCKS 参数。没有修改 Mac 全局系统代理。
6. 完全退出 Mac Codex，确认主进程已经结束，再复制修改前配置到 `config.before-marketplace-fix.toml`。`osascript quit` 返回并不保证进程已退出，不能立刻假定 `open --args` 会作用到新进程。
7. 仅针对日志证实的旧市场来源冲突，执行应用自带官方命令：

   ```bash
   /Applications/ChatGPT.app/Contents/Resources/codex \
     plugin marketplace remove openai-bundled --json
   ```

8. 带正确代理参数重新启动应用：

   ```bash
   open -a /Applications/ChatGPT.app --args \
     --proxy-server=socks5://127.0.0.1:18081
   ```

9. 观察应用自动登记正确运行时市场、安装缺失 Chrome 插件并生成 native host。未手工运行 `scripts/installManifest.mjs`。
10. 运行组件只读检查，确认扩展 installed/enabled 为 true、native host 清单 correct 为 true、目标程序存在且可执行。
11. 经用户明确授权，在 Mac 原有测试聊天中发送一次浏览器实测指令。该聊天通过 Chrome skill 指定的浏览器工具进行验证，结果见下节。
12. 将临时 SSH 转发迁移为独立隐藏的后台 SSH 进程，并保存手动 Connect/Stop 辅助脚本。验证新通道的 SOCKS5、复用、应用参数和停止预览。没有注册开机自启或计划任务。

将来只在同样的证据下执行第 7 步。普通的断线或目标网站失败不需要重复移除市场。

## 关键时间与证据

以下日期均为 2026-10-23，北京时间。换算关系是：北京时间 = 原始日志 UTC 时间 + 8 小时。

| 北京时间 | 证据与含义 |
| --- | --- |
| 约 14:01 | 应用因 Chrome 不在当时可用的运行时市场名单中，自动移除插件 |
| 约 14:17 | 网络路径恢复；运行时市场已写入 Chrome，但旧来源冲突仍阻止安装 |
| 14:29:29 | 正确运行时市场登记成功，日志 `plugin_marketplace_add_succeeded` |
| 14:29:33 起 | 检测到扩展，应用请求安装缺失 Chrome 插件，随后安装成功 |
| 14:36–14:39 | Mac Codex 真正执行 Chrome 功能实测并核对截图 |
| 随后 | 后台独立通道、PowerShell 5.1 脚本复用与停止预览验证完成 |

报告不上传整份应用日志；上表和 JSON 保留必要结论，避免包含账号、私人页面及请求参数。

## 组件检查与浏览器实测

本次插件源与 CLI 路径已实际验证。后续版本先确认这些文件仍存在，再运行：

```bash
nodebin='/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node'
plugin='/Users/apple/.codex/plugins/cache/openai-bundled/chrome/26.727.51351'
"$nodebin" "$plugin/scripts/check-extension-installed.js" --browser chrome --json
"$nodebin" "$plugin/scripts/check-native-host-manifest.js" --browser chrome --json
```

扩展检查为 installed/enabled；native 清单的 name、扩展 origin 和目标程序均正确。Mac Codex 的真实浏览器操作结果：

| 操作 | 结果 |
| --- | --- |
| 建立 Chrome 插件连接 | 成功 |
| 只读列出原有标签页 | 19 个；未上传其标题或地址 |
| 新建专用测试页 | 成功 |
| 打开 `https://example.com/` | 成功，标题 `Example Domain` |
| 读取 DOM | 成功；包含说明文字和 `Learn more` 链接 |
| 截图 | JPEG，1440×768，59123 字节 |
| 点击 `Learn more` | 成功进入 `https://www.iana.org/help/example-domains`，标题 `Example Domains` |
| 返回 | 成功回到 example.com，并重新读取 URL、标题、DOM |
| 清理 | 专用测试标签页已关闭，原有标签页未被测试操作 |

截图 SHA-256：

```text
2935ad13227ac7f675b86bc7c8ae971d383bd29357ec701ec46e596c1c2f6ab5
```

截图字节实际为 JPEG，最初的 `.png` 文件名已纠正为 `.jpg`。仓库中的图像与 Mac 原始截图哈希相同。

## 下次如何恢复

- Windows 远程操作：先读 [Windows 恢复步骤](windows-remote-recovery.md)，建立网络、核对版本、按故障类型处理。
- Mac 本机操作：先读 [本机恢复手册](mac-local-recovery.md)，或把 [提示词](mac-codex-prompt.md) 交给本机 Codex。需要退出应用的步骤由用户在外部终端执行。
- 若只需重新连上现有网络通道，运行 Connect 辅助入口即可，不重复本次市场修正、安装和历史配置恢复。
- 若 Windows 不在线，Mac 必须有自己实际可用的网络通道，或由其他受信任设备提供通道。仓库中的命令不会凭空提供代理服务。

## 已验证与尚未验证的边界

已验证：本次软硬件组合、保留 API/provider、应用自动安装、组件检查、真实 Chrome 操作、独立隐藏 SSH 创建、Connect 复用、已有应用参数检查，以及最终 Windows PowerShell 5.1 的复用和 `Stop -WhatIf`。

尚未实际执行：连接脚本的“应用未运行时请求启动”分支、Stop 脚本的实际停止动作、Mac 独立代理部署、电脑重启后的自动恢复、从 GitHub 重新装回整台 Mac，以及旧应用副本的可启动性。文档中未来操作步骤不应被描述为这些分支已通过测试。

本次本地备份不包含 Chrome profile/扩展内部存储、系统 Keychain、操作系统设置、完整应用包、活动连接和服务器端状态。后续如须恢复配置，应比较当前值与本地备份，只恢复经诊断确需恢复的部分。
