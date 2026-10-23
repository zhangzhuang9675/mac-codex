# 复制给办公 Mac Codex 的恢复提示词

适用于这台办公 Mac 的 Codex + Chrome 再次无法连接、无法操作或插件消失时。下面整段可复制给 Mac 上的 Codex；其中包含保护当前活动会话的约束。

---

请帮助我诊断并恢复这台 Mac 的 Codex Chrome 插件。先读取恢复资料仓库：

https://github.com/zhangzhuang9675/mac-codex

优先读仓库 README、Mac 本机恢复操作手册、修复验证记录和相关脚本。仓库是恢复说明与脱敏证据，不能当成完整系统备份。如果无法联网读取，先使用我本地保存的仓库副本；缺少资料时如实指出，先做不依赖网络的只读诊断，不要凭印象覆盖配置。

这台设备在 2026 年 10 月 23 日的工作基线是：办公 Mac，设备名“una 的 MacBook Pro”，用户 `apple`，当时局域网地址 `10.1.1.211`，macOS `12.7.6`，Intel `x86_64`；Codex 应用为 `/Applications/ChatGPT.app`，版本 `26.727.51351`，保留原有 API/provider 配置。请先核对本机实际身份、版本、架构与路径，变化后不要盲套旧值。

本次原故障与修复：功能服务的网络/DNS/TLS 有问题，曾使 Chrome 不在可用运行时市场并被自动卸载；恢复网络后，发现 `openai-bundled` 仍登记旧来源 `/Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled`。在退出应用并备份配置后，通过官方 CLI 移除旧市场登记，应用重启时自动生成运行时市场，自动安装 Chrome 插件与 native host。旧缓存直接放回去曾被应用再次移除，所以不要重做盲目覆盖。

请遵守以下工作顺序和边界：

1. **保留 API 使用方式。** 不切换到订阅登录，不替换 provider，不读取、展示、上传认证文件或配置中的密钥；不修改服务功能门控来假装功能可用。需要备份配置时只在 Mac 本地私有目录保留，不上传原始 `config.toml`、`auth.json`、Chrome Profile、私钥、完整日志或私人聊天。
2. **先只读诊断五层依赖：** 网络能否访问 Codex 功能服务；应用实际外部 Chrome 功能与运行时市场是否包含 Chrome；`openai-bundled` 实际登记来源是否正确；正确 Chrome 用户资料中的扩展是否已安装启用；native manifest 及其目标程序是否正确存在且可执行。普通 feature 标记为 true 或内置 Browser 可用，不足以证明外部 Chrome 可用。
3. **区分网络路径。** 本次已验证的方案是 Windows 原有代理 `127.0.0.1:10808` 经 SSH 反向转发到 Mac `127.0.0.1:18081`，Mac Codex 使用 `--proxy-server=socks5://127.0.0.1:18081`。它依赖 Windows、原有代理和隧道在线。若通道失效，让我在那台 Windows 执行仓库对应的连接辅助步骤；不要假设 Mac 自带这个代理。Mac 自己的独立代理本次没有部署或验证；只有我提供经确认可用的实际协议和端口，或已确认本机直连正常后，才能采用独立方案。不要自行安装未知代理、导入订阅、修改全局代理或增加开机任务。
4. **保护正在运行的本机会话。** 如果你就在这台 Mac 的 Codex 里，不要自动退出、强杀或重启自己。涉及退出应用的操作，先把已取得的诊断、备份位置、下一步命令与验证步骤写入本机桌面的 `Codex-recovery-next-steps.md`，再让我保存任务、手动退出，在独立“终端”执行。已经运行的应用可能忽略新传入的 `open --args`，不要因此误判代理参数生效。
5. **市场修复必须符合条件。** 只有证明当前版本仍使用对应运行时机制、网络与功能信息已恢复、旧市场登记实际存在且产生冲突时，才考虑本次已验证的命令：`/Applications/ChatGPT.app/Contents/Resources/codex plugin marketplace remove openai-bundled --json`。先核对当前 CLI 帮助，先本地备份配置，且在应用退出后由外部终端执行。之后让官方应用自动重建市场与安装组件。不要每次启动都移除市场，不要清空其他市场或插件。
6. **安装组件走官方流程。** Chrome 扩展与 Codex 插件是不同环节。需要时通过当前版本官方插件 UI/Chrome 安装入口操作；读取当前 Chrome skill 及 troubleshooting 文档。禁止运行 `scripts/installManifest.mjs`、手工伪造 native manifest、制造 `latest` 链接或覆盖旧缓存。`Try now` 按钮、清单存在或文件复制成功都不是最终验收。
7. **权限只处理实际错误。** 遇到明确系统授权错误时告诉我对应程序与系统页面，由我手动授权。不要改 TCC 数据库或关闭 SIP。本次 SSH 设置界面控制曾授权 `sshd-keygen-wrapper` 和 `osascript` 的辅助功能，不代表本机 Chrome 恢复必须重复授予这些权限。
8. **不要删除或盲目回退应用。** `26.727.51351` 是本次可用基线；历史旧应用目录只作为线索，不是保证可恢复的安装包。版本已变化时先判断当前版本实际兼容性，保留现有应用与数据。
9. **必须实测。** 组件检查通过后，在这台 Mac 上读取并遵循当前 Chrome control skill，用指定浏览器客户端与 Node 工具（本次是 `node_repl`）进行真实调用。仅在新建专用测试标签中打开 `https://example.com/`，读取 `Example Domain` 标题和 DOM，保存截图，点击 `Learn more` 到 IANA，再返回并关闭该测试标签。保持原有标签、登录状态与私人页面，不用 shell/AppleScript/直接 CDP 代替 Chrome 工具。如果该工具尚不可用，明确写“组件检查通过，真实操作未验证”，不要宣称修好。
10. 输出简明恢复报告：本次根因与证据、执行过的改动、本地备份位置、组件和真实浏览器测试结果、截图与时间、仍依赖的网络条件和未验证分支。公开仓库只保存脱敏说明和证据，绝不上传凭据或私有原始文件。

本次可核对的路径（先检查实际是否存在）：

```text
CLI: /Applications/ChatGPT.app/Contents/Resources/codex
Node: /Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node
官方 Chrome 资源: /Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled/plugins/chrome
插件缓存: /Users/apple/.codex/plugins/cache/openai-bundled/chrome/26.727.51351
Native manifest: /Users/apple/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.openai.codexextension.json
扩展 ID: hehggadaopoacecdllhhajmbjkdcmajg
本次正确运行时市场: /Users/apple/.codex/.tmp/bundled-marketplaces/openai-bundled
Mac 修复前备份: /Users/apple/.codex/repair-backups/chrome-20261023-035751
Windows 辅助资料: E:\CodexBackups\office-mac-chrome-20261023
```

`.tmp` 市场路径由该版本应用生成，不是永久备份。不要把这段路径表当成要手动写入系统的配置。

本次确实通过的验收是：2026-10-23 北京时间约 14:36–14:39，Mac Codex 连接到原有 19 个标签页，在新建标签完成 example.com 导航、DOM 读取、1440×768 JPEG 截图、点击到 IANA、返回和关闭。当前恢复结束时请重新取得相同类型的真实证据；历史结果不能证明现在仍正常。

---

首次只需将上面整段交给 Mac Codex。若报告中的网络步骤需要 Windows 支持，先让 Windows 端恢复通道；若本机 Codex 本身已无法运行，则由使用者在独立终端或另一台已授权电脑上按手册恢复，不能依赖这段提示词自动启动失效的应用。
