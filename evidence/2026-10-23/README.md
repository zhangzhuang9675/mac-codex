# 2026-10-23 验证证据说明

这些文件记录本次实际修复的结果。历史验证不代表设备当前或未来仍可用，恢复后需要重新测试。

| 文件 | 内容 |
| --- | --- |
| `verification-after-repair.json` | 设备、组件、API 配置保留结论和 Mac Chrome 真实操作结果；公开副本省略私人聊天标识 |
| `helper-verification.json` | Windows 手动连接脚本的实际运行范围；公开副本省略临时 PID |
| `syntax-verification.json` | 三个已验证 PowerShell 脚本的语法结果与 SHA-256；校验对象为 `scripts/windows/` 下原样副本 |
| `chrome-functional-test.jpg` | Mac Chrome 插件获取的公开示例网页截图，不含原有用户页面 |

截图在北京时间 2026-10-23 约 14:37 获取，JPEG 1440×768，59123 字节，SHA-256：

```text
2935ad13227ac7f675b86bc7c8ae971d383bd29357ec701ec46e596c1c2f6ab5
```

原始日志与配置备份保留在用户设备本地。仓库没有原有标签页列表、私人聊天内容、API key、SSH 私钥或 Chrome profile。

`syntax-verification.json` 的 PowerShell 版本描述语法检查环境；Windows PowerShell 5.1 的实际复用及停止预览结果记录在 `helper-verification.json`。应用未运行时的脚本启动分支和 Stop 的真正停止动作未在本次执行。
