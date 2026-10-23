# 办公 Mac 的 Codex + Chrome 本机恢复操作手册

本手册记录 2026 年 10 月 23 日已完成修复的办公 Mac，并给出以后由 Mac 使用者或该 Mac 上的 Codex 执行的恢复流程。**保留现有 API 使用方式，先判断故障，再修复对应环节。** 当前已验证的网络方案仍依赖 Windows；Mac 本机独立代理是满足条件后可采用的方案，本次未部署、未验证。

配套的 [Mac Codex 恢复提示词](mac-codex-prompt.md) 可以直接交给该 Mac 上的 Codex。建议趁当前网络正常时在 Mac 本地保存一份本仓库，避免故障发生后无法访问 GitHub。

## 1. 已确认的设备与工作基线

| 项目 | 2026-10-23 的值 |
| --- | --- |
| 设备 | una 的 MacBook Pro，办公 Mac |
| SSH 用户与当时的局域网地址 | `apple@10.1.1.211`；地址将来可能变化，先在 Mac 上核对 |
| 系统与架构 | macOS `12.7.6`，Intel `x86_64` |
| Codex 应用 | `/Applications/ChatGPT.app` |
| 应用标识 / 已验证版本 | `com.openai.codex` / `26.727.51351` |
| 认证方式 | 原有 API/provider 配置；修复前后相关配置节一致 |
| 官方 CLI | `/Applications/ChatGPT.app/Contents/Resources/codex` |
| 应用附带 Node | `/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node`，本次为 `v24.14.0` |
| Chrome 扩展 ID | `hehggadaopoacecdllhhajmbjkdcmajg` |
| 已恢复的 Chrome 插件 | `/Users/apple/.codex/plugins/cache/openai-bundled/chrome/26.727.51351` |
| 本机通信清单 | `/Users/apple/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.openai.codexextension.json` |
| 清单指向的已验证程序 | `/Users/apple/.codex/plugins/cache/openai-bundled/chrome/latest/extension-host/macos/x64/ChatGPT for Chrome`；当时 `latest` 指向 `26.727.51351` |
| 本次修复前的 Mac 本地备份 | `/Users/apple/.codex/repair-backups/chrome-20261023-035751` |
| Windows 上的恢复辅助资料 | `E:\CodexBackups\office-mac-chrome-20261023` |

这些路径是本次事实记录。以后用户名、应用名称、安装位置、版本或架构发生变化时，必须依据本机实际情况重新定位，不能把旧路径、旧扩展版本或 x64 程序强行套用到新环境。

本次先前回退版本的历史线索是从 `26.730.61309` 回到 `26.727.51351`，旧应用曾保留在 `/Applications/ChatGPT.app.backup-26.730.61309d`。这只是查找旧文件的线索；存在旧目录或签名检查通过，不代表已具备可用的完整安装包。**不要删除当前应用，也不要仅根据这条历史记录降级或覆盖。**

## 2. 本次故障与确实执行过的修复

本次有两个相互独立的阻塞因素：

1. Mac 访问功能服务存在 DNS 与直连 TLS 问题。指定经可信查询取得的真实目标 IP 后，直连仍失败，因此仅更换 DNS 不足以解决；使用 Windows 已有代理，经 SSH 反向转发供 Mac Codex 单独使用后，应用恢复获取可用的浏览器功能与插件市场信息。
2. `openai-bundled` 曾登记旧来源 `/Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled`，与该版本生成的运行时市场来源冲突。退出应用、备份配置后，通过官方 CLI 移除旧市场登记，再正常启动应用，Codex 自动重新生成市场、安装 Chrome 插件并完成本机通信组件登记。

本次正确的运行时市场来源为：

```text
/Users/apple/.codex/.tmp/bundled-marketplaces/openai-bundled
```

`.tmp` 是应用运行时生成位置，**不能把它当永久安装包或备份目录，也不要手工固定该路径作为通用修复。** 当时应用自带市场资源还在，问题发生在实际登记的来源与运行时协调。

网络未恢复时，应用日志曾以 `reason=not_in_bundled_marketplace_plugin_names` 自动卸载 Chrome 插件。直接把缓存文件或配置块放回去，仍会被应用再次移除。因此，“文件暂时出现”或“安装按钮变成 Try now”不足以证明恢复成功。

## 3. 开始前：保护当前会话与隐私

- 若执行恢复的正是当前 Mac Codex，先把诊断结论、待执行命令和验证步骤写入本地文件，例如桌面的 `Codex-recovery-next-steps.md`，再让使用者保存任务、手动退出应用，并在独立的 macOS“终端”执行后续步骤。**不要从活动中的本机会话自动退出、强杀或重启自己。**
- 修改市场登记前，仅将需要恢复的配置备份到该 Mac 的私有目录。不要将 `auth.json`、原始 `config.toml`、API token、SSH 私钥、Chrome Profile、完整日志或私人聊天上传 GitHub，也不要在聊天中输出其内容。
- 本仓库是说明、辅助脚本和脱敏验证记录，不能替代 Mac 的完整备份。Mac 本地修复备份可能包含敏感配置，只在原设备或用户控制的私有存储保留。
- 不切换认证方式，不要求订阅登录，不替换 provider，不伪造功能门控，不手工安装 native host。

## 4. 先诊断：按照依赖顺序检查

### 4.1 确认当前设备、系统与应用

以下是只读检查，本次路径必须先确认存在：

```bash
sw_vers -productVersion
uname -m
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  '/Applications/ChatGPT.app/Contents/Info.plist'
'/Applications/ChatGPT.app/Contents/Resources/codex' --version
'/Applications/ChatGPT.app/Contents/Resources/codex' plugin marketplace --help
```

若版本不是 `26.727.51351`，记录新版本和实际路径，先核对新版本附带的说明与 CLI 帮助，再决定操作。不要直接覆盖成旧版本。可只读运行 `codesign --verify --deep --strict '/Applications/ChatGPT.app'` 检查应用签名，但签名正常不能证明插件、网络和浏览器操作正常。

### 4.2 区分网络问题和网页自身问题

检查是否只有某个业务网站打不开，还是 Codex 的功能服务也无法访问。本次使用的 Mac 代理端点为 `127.0.0.1:18081`，可在“终端”进行无认证内容的连通性检查：

```bash
/usr/bin/curl --proxy socks5h://127.0.0.1:18081 \
  --connect-timeout 5 --max-time 15 -sS -o /dev/null \
  -w 'HTTP %{http_code}\n' 'https://ab.chatgpt.com/v1/initialize'
```

本次该 GET 请求返回 HTTP `403`，表示请求能到达服务；**不能据此认定功能初始化 POST 成功**。还需要检查应用随后产生的功能状态和插件加载日志。超时、代理握手失败、TLS 重置应先处理网络；单个目标网站失败则要单独判断目标网络，不能直接恢复插件或认证。

### 4.3 检查外部浏览器功能和市场来源

- 使用本机 CLI 的只读 `features list` 及当前日志检查外部浏览器功能。普通 `browser_use_external=true` 只是一个必要证据；还要确认应用实际提供 Chrome，并且运行时市场包含 Chrome。不要把内置 Browser 可用误当成外部 Chrome 已可用。
- 通过官方 CLI 的 `plugin marketplace --help` 查找当前版本提供的只读列举入口，确认 `openai-bundled` 实际登记来源。仅摘录市场名称和路径，不输出配置全文。
- 本次应重点找 `bundled_plugins_runtime_marketplace_written`、包含 `chrome` 的插件名称列表、`plugin_install_succeeded`、`plugin_uninstall_requested` 与对应原因。日志目录为 `~/Library/Logs/com.openai.codex/`。只摘录必要行，去掉 token、URL 查询参数、账号与聊天内容。

功能服务仍不可达或 Chrome 仍被功能门控排除时，先解决这一层。不要靠反复复制插件缓存抵消应用的自动卸载逻辑。

### 4.4 检查扩展与本机通信组件

在 Chrome 的 `chrome://extensions/` 中确认正确的扩展 ID、启用状态与当前使用的 Chrome 用户资料。不要删除 Profile，也不要因某个资料里未安装而清理其他资料。扩展和 Codex 插件是两个环节：商店扩展安装完成，并不表示应用插件和本机通信清单已恢复。

本次版本带有官方只读检查器，先确认文件存在，再执行：

```bash
codex_node='/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node'
chrome_source='/Applications/ChatGPT.app/Contents/Resources/plugins/openai-bundled/plugins/chrome'
"$codex_node" "$chrome_source/scripts/check-extension-installed.js" --browser chrome --json
"$codex_node" "$chrome_source/scripts/check-native-host-manifest.js" --browser chrome --json
```

这些检查器、参数和资源目录已在本次环境使用；未来版本若缺失，改读该版本 Chrome skill 及其 troubleshooting 文档，不要自己写一个“通过”的结果。检查应覆盖：扩展已安装并启用、native manifest 正确、目标程序存在且可执行、`latest` 链接与当前安装版本一致。

## 5. 网络恢复的两条路径

### 路径 A：复用本次已验证的 Windows 通道

此方案已经用于完成本次真实浏览器测试，依赖 Windows 在线、原有代理监听 Windows `127.0.0.1:10808`、SSH 可达，以及 Mac `127.0.0.1:18081` 的反向转发。Mac 必须保持“远程登录”开启，地址与用户核对正确。

在那台 Windows 的 PowerShell 中执行：

```powershell
& 'E:\CodexBackups\office-mac-chrome-20261023\Connect-OfficeMacChrome.ps1' -LaunchCodex
```

脚本检查与复用通道，必要时创建专属后台 SSH。已运行但缺少代理参数的 Mac Codex 会收到手动退出提示，脚本不会强制退出它。原有 SSH 密钥仅留在 Windows 本地，**不需要上传到仓库，也不要向 Mac 或聊天发送私钥**。

当前手册不包含该私钥。Windows 更换、丢失私钥或 Mac 地址变化时，要按新的可信 SSH 连接重新建立密钥授权及主机指纹验证；不要关闭主机指纹校验，也不要把“同一个局域网”当作已确认主机身份。

如果由本机使用者在独立“终端”启动 Mac Codex，先确认通道可用、保存任务并手动退出旧应用，再执行本次使用过的启动命令：

```bash
open -a '/Applications/ChatGPT.app' --args \
  --proxy-server=socks5://127.0.0.1:18081
```

`open` 遇到已运行应用可能复用原进程，不能假定新参数已生效。确认当前实例已退出后再启动。启动成功不等于 Chrome 测试成功。日常连接脚本的“应用未运行时启动”分支，以及停止脚本的实际停止动作，本次没有完成动态验证；已有应用的参数检查、隧道新建、复用、SOCKS 检查和停止预览已验证。

### 路径 B：Mac 使用自己可用的网络或本机代理

这是未来替代方案，**本次没有安装、配置或验证 Mac 独立代理**。仅在 Mac 已有经用户确认可用的代理或直连网络，并且实际功能服务检查通过时采用。没有这些条件，就不能声称“本机独立恢复完成”。

若用户已有 Mac 本地代理，先核对真实协议、监听地址和端口，再用它检查功能服务，并按相同地址给 Codex 设置应用专用的 `--proxy-server` 启动参数。不要猜端口，不要复制 Windows 的 `10808` 到 Mac，也不要把 Windows 通道端口 `18081` 当作 Mac 自带代理。

该分支没有固定可复制的端口命令，因为本次并没有这样的 Mac 代理。先记录用户确认的实际端点，再生成启动命令。禁止为本任务自行安装未知代理、导入代理订阅、修改系统全局代理或增加开机任务。

## 6. 仅在证据一致时，纠正旧市场来源

这是本次实际成功的修复动作，**不是每次启动或每种 Chrome 故障都要执行的重置命令**。必须先同时确认：当前版本仍采用该运行时市场机制；网络与功能信息已恢复；`openai-bundled` 实际仍登记着本次旧来源并产生冲突；不是扩展被禁用或单个网站网络失败。

若这些条件不成立，停止套用该动作，继续处理已经找到的故障。

操作前，Mac Codex 应保存任务并由使用者手动退出。下面由使用者在独立“终端”执行；如果当前就是本机 Codex 在排障，应先将这些步骤保存到本地下一步文件，再交给使用者执行。

先创建只在 Mac 本地保留的配置备份，不读取或打印其内容：

```bash
recovery_backup="$HOME/.codex/repair-backups/manual-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$recovery_backup"
chmod 700 "$recovery_backup"
if [ -f "$HOME/.codex/config.toml" ]; then
  cp -p "$HOME/.codex/config.toml" "$recovery_backup/config.toml"
  chmod 600 "$recovery_backup/config.toml"
fi
```

再核对当前 CLI 帮助及市场名称，确认仅移除错误的 `openai-bundled` 登记：

```bash
'/Applications/ChatGPT.app/Contents/Resources/codex' plugin marketplace remove --help
'/Applications/ChatGPT.app/Contents/Resources/codex' \
  plugin marketplace remove openai-bundled --json
```

第二条是本次实际成功执行的官方命令。它应由条件判断触发，不能放入日常启动脚本循环执行。之后通过已确认可用的网络方式启动 Codex，让应用自行生成运行时市场与安装组件，再检查官方 UI 和日志。

如应用要求手动安装插件，从该版本的官方“插件”页找到 Chrome 并安装；Chrome 扩展的商店安装入口要按实际界面完成。`codex://settings/computer-use/chrome` 在本次版本曾用于打开 Chrome 设置页，未来版本若不支持，改用实际界面，不要反复盲发深链。

**不要执行 `scripts/installManifest.mjs`，不要手工写 `com.openai.codexextension.json`，不要手工制造 `latest` 链接或把旧插件缓存覆盖回当前版本。** 本次 native host 是由官方应用流程自动恢复的。若自动恢复失败，保留诊断，再按当前 Chrome skill 的 troubleshooting 指引处理。

## 7. 权限处理：只在实际报错时申请

本机 Chrome 插件主要依赖扩展和 native host，不等于需要把所有系统隐私权限全部打开。只有使用具体工具遇到明确权限错误时，才让使用者在系统设置中授权相应程序；不能脚本修改 TCC 数据库或关闭 SIP。

本次远程操作设置界面时，macOS 12 的路径是“系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能”。使用者解锁后，通过“＋”和 Command+Shift+G，分别添加并勾选系统报错对应的：

```text
/usr/libexec/sshd-keygen-wrapper
/usr/bin/osascript
```

这是当时 SSH/AppleScript 操作应用设置界面所需的权限，**不能据此要求所有未来本机恢复都给它们授权**。新版 macOS 对应入口通常为“系统设置 → 隐私与安全性 → 辅助功能”，以本机界面为准。遇到“自动化”等其他权限提示也只处理实际报错指出的对象。屏幕录制或其他权限不得无故扩张。

## 8. 验收：必须由该 Mac 的 Chrome 工具完成实测

组件检查通过后，在 **这台 Mac 的 Codex** 中读取当前安装的 Chrome control skill 及其引用文档，使用 skill 指定的浏览器客户端和 Node 工具，例如该版本的 `node_repl`。不能用当前 Windows 的 Chrome 测试替代；不能用 shell、AppleScript、直接 CDP 或截图文件存在代替 Chrome 插件实际调用。

测试范围：

1. 列出现有标签页，只记录数量；不遍历私人页面内容。
2. 新建专用测试标签页，打开 `https://example.com/`。
3. 读取 `Example Domain` 标题和 DOM，保存网页截图。
4. 点击页面 `Learn more`，确认到达 IANA 的 `Example Domains` 页面；再返回示例页面。
5. 关闭本次测试标签页，保留原有标签页、登录状态和页面。
6. 将时间、设备、版本、组件检查、实际工具调用成功/失败及截图路径写入脱敏验证记录；失败步骤如实保留，不填写推测成功。

如果当前 Mac Codex 没有该 skill 要求的 Node/浏览器工具，应明确报告“组件检查通过，真实操作尚未验证”，补齐官方插件/工具能力后再测试。不要另造旁路宣称完成。

本次已完成的验收是 2026-10-23 北京时间约 14:36–14:39：连接到原有 19 个标签页；在新标签完成导航、标题与 DOM 读取、1440×768 JPEG 截图、点击 IANA、返回与关闭。原有标签页未被测试操作。该结果只证明当时条件下可用；Windows 通道、代理、版本或权限变化后需要重新验收。

## 9. 不同故障对应的下一步

| 现象或证据 | 下一步 |
| --- | --- |
| Windows 代理或 Mac `18081` 不通 | 检查既有代理、SSH 与后台隧道；先恢复网络 |
| 功能服务超时、Chrome 不在运行时市场 | 处理功能初始化网络；保留日志，不反复覆盖缓存 |
| 只有一个业务网站失败，示例站正常 | 诊断该网站的 DNS/TLS/访问限制 |
| 扩展未安装或当前 Chrome Profile 未启用 | 使用正确 Profile 和官方扩展安装入口 |
| 扩展正常、native manifest 缺失 | 使用官方应用插件安装/修复流程，查看日志 |
| 旧市场来源冲突，且满足第 6 节全部条件 | 本地备份配置，手动退出应用后通过官方 CLI 纠正登记 |
| 组件全通过但真实操作失败 | 记录浏览器工具的实际错误，按照当前 Chrome skill 排查 |
| 应用版本、架构或路径改变 | 重新确认兼容性、目录与官方流程，不直接套用本次旧版本路径 |

## 10. 恢复完成应留下的记录

保留设备与系统版本、应用版本、实际使用的代理端点及依赖、市场来源、扩展 ID 与启用状态、native host 检查、功能测试结果、截图哈希和仍未验证的分支。公开记录只保留这些必要信息；私有配置备份与诊断原始文件留在用户本地。

本次的资料不包含完整 Chrome Profile、扩展内部存储、macOS 钥匙串、全系统镜像、完整应用安装包或远端服务器状态，不能承诺恢复所有未来故障，也不能在缺少本地网络条件时承诺完全独立恢复。
