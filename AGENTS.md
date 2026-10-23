# Mac Codex 恢复协作约定

- 用户指定的长期恢复入口是 https://github.com/zhangzhuang9675/mac-codex 。先读 README 和最近一次日期报告，再读对应平台手册。
- 本仓库记录的是一次已验证的历史工作状态。版本、路径、IP 和功能条件都要与当前设备核对，不将旧版本永久固定为唯一正确版本。
- 保留用户正在使用的 API/provider 认证方式。不要要求切换 ChatGPT 订阅登录，不打印或上传凭据。
- 原始 `config.toml`、`auth.json`、SSH 密钥、浏览器 profile、聊天记录、整份日志和含凭据的备份仅保存在设备本地，不提交到本仓库。
- 先区分目标网站网络故障、Codex 功能服务连接、插件市场来源冲突、Chrome 扩展和本机通信组件问题，再实施最小修复。
- 对本次基线，旧 `openai-bundled` 来源冲突通过官方 `plugin marketplace remove` 命令修正；应用自动同步负责插件和 native host。不要手工运行 `installManifest.mjs`、伪造功能门控或修改应用签名文件。
- 在 Mac 本机 Codex 活动聊天中，不自动结束承载自己的应用。先写出诊断和可执行的下一步，由用户在外部终端完成需退出应用的操作。
- 配置变更前先本地备份。不要无条件覆盖整个历史配置，不把本仓库或 Windows 备份当作 Mac 整机恢复镜像。
- 实际浏览器验证必须按当前 Chrome skill 使用浏览器工具，仅新建专用测试标签页；保留原有标签页，验证导航、DOM、截图、点击、返回和清理。文件存在、按钮变为 Try now、HTTP 403 或模型口头回答都不足以证明可用。
- 本仓库的 Windows 脚本原样保留本次验证结果，默认运行目录是 `E:\CodexBackups\office-mac-chrome-20261023`。修改脚本后需更新验证范围及摘要，不能沿用原文件哈希宣称新版本已测。
