# 从 Windows 通过局域网恢复办公 Mac

本步骤对应 2026-10-23 验证的环境。先读 [事件报告](2026-10-23-mac-codex-chrome-recovery-report.md)，确认目标仍是同一台 Mac、同一应用版本和本地用户。

## 所需条件

- Windows 与 Mac 在可互通的局域网；本次 Mac 为 `10.1.1.211`，用户 `apple`。
- Mac 已开启“系统偏好设置 → 共享 → 远程登录”。新系统入口可能为“系统设置 → 通用 → 共享”。
- Windows 的专用 SSH 密钥已经在 Mac 上授权，路径为 `C:\Users\zhang\.ssh\codex-office-mac-repair`。仓库不保存密钥；若原密钥丢失，须在本地新建并通过用户操作授权公钥，不能从报告恢复私钥。
- Mac 的 SSH 主机指纹已经通过可信方式确认。脚本使用严格校验，不自动接受新指纹。
- Windows 既有代理客户端运行，`127.0.0.1:10808` 可用。仅有 SSH 通道不能替代上游代理。

## 从仓库部署连接脚本

本仓库的三个 PowerShell 文件是本次已验证辅助脚本的原样副本。它们使用固定的本次 E 盘运行目录，不在仓库克隆目录内直接运行。

若 E 盘已有这三个文件，优先审阅现有版本，不要在已有 Connect/Stop 正运行时覆盖。若本地已没有脚本，在 Windows PowerShell 中下载或克隆本仓库，然后仅复制脚本：

```powershell
# 将下面路径替换成你的仓库克隆目录。
$repoPath = 'E:\path-to\mac-codex'
$runPath = 'E:\CodexBackups\office-mac-chrome-20261023'
New-Item -ItemType Directory -Path $runPath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $repoPath 'scripts\windows\Connect-OfficeMacChrome.ps1') -Destination $runPath
Copy-Item -LiteralPath (Join-Path $repoPath 'scripts\windows\OfficeMac-Recovery.Common.ps1') -Destination $runPath
Copy-Item -LiteralPath (Join-Path $repoPath 'scripts\windows\Stop-OfficeMacChromeTunnel.ps1') -Destination $runPath
```

本次配置备份和运行日志仍留在 E 盘与 Mac 本机。不要把它们复制进仓库。

## 1. 检查 SSH

```powershell
ssh -F none -i 'C:\Users\zhang\.ssh\codex-office-mac-repair' -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=8 apple@10.1.1.211 'sw_vers; uname -m'
```

本次 `-F none` 用来绕过 Windows 原有 SSH 配置的所有权错误。不要为了本次修复去重设整个 `.ssh` 目录的权限，也不要在聊天中粘贴密码或私钥。

连接超时先核对 Mac 当前 IP、远程登录和网络；认证失败检查公钥授权。主机指纹变化先现场核验，不盲删 known_hosts。

## 2. 建立或复用网络通道

```powershell
& 'E:\CodexBackups\office-mac-chrome-20261023\Connect-OfficeMacChrome.ps1'
```

入口检查 Windows 10808、通过 SSH 对 Mac 18081 做 SOCKS5 握手，再复用或建立隐藏的独立 SSH。两个监听均限定为 loopback，没有将代理开放到局域网。

实际转发方向是：

```text
Mac Codex → Mac 127.0.0.1:18081 → SSH -R → Windows 127.0.0.1:10808 → 网络服务
```

## 3. 检查应用启动参数

```powershell
& 'E:\CodexBackups\office-mac-chrome-20261023\Connect-OfficeMacChrome.ps1' -LaunchCodex
```

应用已经带正确参数时，入口保持现状。应用正在运行但没有正确参数时，保存任务并让用户手动退出 Mac Codex，再重跑该命令。不要强制结束用户的活动聊天。

脚本中的“应用未运行时发起启动”分支已经静态审阅，本次没有单独执行该分支。实际的应用专属代理启动命令曾在本次修复中成功执行：

```bash
open -a /Applications/ChatGPT.app --args \
  --proxy-server=socks5://127.0.0.1:18081
```

应用版本若已改变，入口会要求重新核对。本报告的旧版本不是强制回退要求。

## 4. 按故障证据继续

| 当前表现 | 下一步 |
| --- | --- |
| SSH 或 SOCKS 握手失败 | 先修网络、密钥或转发，不动插件 |
| 某个网站报连接错误，但插件能列标签页 | 分开检查目标网站网络与浏览器集成 |
| Chrome 扩展未安装 / 未启用 | 使用应用当前受支持的 Chrome 安装入口，由用户完成必要浏览器授权 |
| 扩展正常但 native host 缺失 | 检查 Codex 功能可用性、市场同步和安装日志，由应用官方流程修复 |
| 日志再次明确出现同名市场旧来源冲突 | 先备份，完全退出应用后按事件报告修正旧登记 |
| 应用或插件版本变化 | 读取新版本 skill 和官方入口，重新验证路径及命令 |

本次确认的直接设置入口曾为 `codex://settings/computer-use/chrome`，但版本变化后可能调整。它打开的是安装/设置页面，不能替代实际浏览器验证。若一般设置链接落到“常规”，从应用侧栏选择相应设置；不要反复假定深链接成功。

如需跨 SSH 操作应用设置界面，系统可能需要用户手动授权辅助功能。本次授权过 `sshd-keygen-wrapper` 和 `osascript`。仅在系统明确拒绝且确实需要 GUI 操作时处理，不把辅助功能授权作为所有恢复的前置步骤。不修改 TCC 数据库。

## 5. 验证和记录

从当前版本 Chrome skill 指定的浏览器工具完成：只读列标签页、新建专用页、导航、DOM、截图、链接点击、返回、关闭专用页。可使用 [给 Mac Codex 的提示词](mac-codex-prompt.md) 中的实测要求；向另一条聊天发送指令需要用户明确授权。

用户原有标签页不作为测试目标。不要将原有页面列表、账号信息或整份日志上传 GitHub。

## 停止和重启后的行为

先预览：

```powershell
& 'E:\CodexBackups\office-mac-chrome-20261023\Stop-OfficeMacChromeTunnel.ps1' -WhatIf
```

需要断开时去掉 `-WhatIf`。实际停止分支本次未执行；预览已验证能识别专用进程。脚本要求 PID、创建时间、命令行等全部匹配，不会认领其他会话的 SSH。

Windows 重启、代理退出或网络断开后，需要手动重跑连接入口。此入口没有注册自启动，不承诺通道自动重连。Mac 若要脱离 Windows 独立使用，需要先配置它自身可用的网络路径，参见 [本机手册](mac-local-recovery.md)。
