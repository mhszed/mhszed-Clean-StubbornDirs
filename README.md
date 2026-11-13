# Clean-StubbornDirs

A small PowerShell tool for Windows that force-deletes **locked / access-denied folders** — the kind left behind by Windows upgrades (e.g. `C:\$WINDOWS.~BT`, `Windows.old`), bad uninstallers, or folders owned by `SYSTEM` / `TrustedInstaller` that a normal "Delete" refuses even under an Administrator account.

一个用于 Windows 的 PowerShell 小工具：强制删除**被锁定 / 拒绝访问的文件夹**（如系统升级残留 `C:\$WINDOWS.~BT`、卸不干净的软件目录、归 `SYSTEM`/`TrustedInstaller` 所有的顽固目录）。

> 💡 **C 盘爆满？** 可以用本工具清理系统升级残留（`$WINDOWS.~BT`、`Windows.old`）、软件安装残留和 Temp 临时文件，快速释放大量空间。本工具就是在实际清理 C 盘时做出来的。

---

## 🚨 严重警告 / SEVERE WARNING

**`Run-Clean-StubbornDirs.cmd` 有风险：当你输入一个路径后，它会把这个文件夹「连同文件夹本身」整个永久删除**（不是只清空里面的内容），而且**不进回收站、无法恢复**。**路径输错 = 误删别的目录，甚至让系统无法启动。**

使用前务必：

- 先看预演结果，确认路径就是你要删的那个文件夹；
- 重要数据先备份；
- 不确定就别用它删。

作者对任何数据丢失 / 系统损坏**不承担责任**。

---

## 文件说明 / What each file does

| 文件 | 作用（一句话） |
|---|---|
| `Clean-StubbornDirs.ps1` | 主脚本。接管所有权 + 授权 + 删除指定文件夹；支持 `-WhatIf` 预演、`-Yes` 免确认。 |
| `Run-Clean-StubbornDirs.cmd` | **通用启动器**：自己输入文件夹路径，**连同文件夹本身一起删**；先预演、输入 Y 才真删。**有风险，见上方警告。** |
| `一键删除系统升级残留.cmd` | **一键工具①**：专门删 `C:\$WINDOWS.~BT`（系统升级残留，约 27 GB）。双击 → UAC 点「是」→ 输入 Y。 |
| `Clear-TempDirs.ps1` | **Temp 清理逻辑**：只删 N 天前（默认 1 天）的文件，跳过占用文件，不删 Temp 目录本身。 |
| `一键清理Temp.cmd` | **一键工具②**：双击清理 `%TEMP%` 和 `C:\Windows\Temp` 里的旧垃圾；先预演、输入 Y 才删。 |
| `README.md` | 使用说明（本文件）。 |
| `LICENSE` | MIT 开源协议。 |

---

## ⚠️ Disclaimer / 免责声明

**Read this before using.**

- This tool **permanently deletes files**. Deleted data **cannot be recovered** (it does not use the Recycle Bin).
- It **changes file ownership and permissions** (`takeown` / `icacls`) on the target directories and everything inside them.
- You must be sure of the target path. **A wrong path can break your system.**
- Deleting Windows system folders incorrectly can make Windows unbootable. **Only delete folders you know are safe to remove.**
- The author provides this software **"AS IS", without warranty of any kind**, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement.
- **In no event shall the author be liable** for any claim, damages or other liability — including data loss, system damage or business interruption — arising from, out of or in connection with the software or its use.
- **Always run with `-WhatIf` first**, test on a non-critical machine, and keep backups of anything important.
- You are solely responsible for what you delete.

**使用前请务必阅读：**

- 本工具会**永久删除文件**（不进回收站），删除后**无法恢复**。
- 它会**修改目标目录及其所有内容的属主与权限**（`takeown` / `icacls`）。
- 请务必确认目标路径正确，**路径选错可能导致系统损坏甚至无法启动**。
- 作者按**「原样」提供本软件，不提供任何明示或暗示的担保**（包括适销性、特定用途适用性、不侵权等）。
- **作者不对任何因使用本工具造成的数据丢失、系统损坏、业务中断等损失承担责任。**
- **请先用 `-WhatIf` 预演**，先在非关键机器上测试，重要数据务必备份。
- 删什么、后果如何，由使用者自行负责。

---

## Requirements / 环境要求

- Windows 10 / 11 (Windows PowerShell 5.1 or PowerShell 7+)
- For system-owned folders (`$WINDOWS.~BT`, `Windows.old`, ...): an **elevated** ("Run as Administrator") PowerShell.
- No third-party dependency. Uses built-in `takeown`, `icacls`.

---

## Usage / 使用方法

```powershell
# 1) Dry run first (recommended) — shows what WOULD be deleted, deletes nothing
.\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT' -WhatIf

# 2) Actually delete (prompts for confirmation)
.\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT'

# 3) Skip the confirmation prompt (non-interactive)
.\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT' -Confirm:$false

# 4) Multiple targets, and stop/restart Windows Update services around the delete
.\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT','C:\Windows\SoftwareDistribution\Download' -StopUpdateService -Confirm:$false

# 5) Custom log location
.\Clean-StubbornDirs.ps1 -Path 'D:\Leftover' -LogPath 'D:\clean.log'
```

> If PowerShell blocks the script: `powershell -ExecutionPolicy Bypass -File .\Clean-StubbornDirs.ps1 -Path '...'`

### Double-click launcher / 一键启动（推荐给不想敲命令的人）

Windows 下可直接双击启动器，无需手写命令：

1. 双击 **`Run-Clean-StubbornDirs.cmd`**（或桌面上的「清理顽固文件夹」快捷方式）
2. 弹出 UAC 点「**是**」（系统目录需要管理员权限）
3. **输入或粘贴**目标文件夹的完整路径，回车
4. 先显示**预演结果**（不会删除）；确认无误后输入 **`Y`** 回车才真正删除

> 若双击没有弹出管理员权限提示，可改成 **右键 → 以管理员身份运行**。

### 一键删除系统升级残留 / One-click delete `C:\$WINDOWS.~BT`

双击 **`一键删除系统升级残留.cmd`**（UAC 点「是」→ 输入 `Y`）：

- 专门删除 **`C:\$WINDOWS.~BT`**（Windows 功能更新残留，常见约 20–30 GB）；
- 先尝试**快速删除**（`rd /s /q`），删不动时自动 `takeown` + `icacls` **接管所有权后再删**；
- 删除前会显示目标路径，输入 **`Y`** 才真正删除；
- 结束后在桌面写 `WindowsBT_delete_log.txt`，并显示 C 盘剩余空间。

> 若双击没有弹出管理员权限提示，可改成 **右键 → 以管理员身份运行**。

### 一键清理 Temp / Clean temp files

双击 **`一键清理Temp.cmd`**（UAC 点「是」）：

- 清理 **`%TEMP%`（当前用户临时目录）** 和 **`C:\Windows\Temp`（系统临时目录）** 中**修改时间超过 1 天**的文件；
- **跳过正在被占用的文件**，也**不删除 Temp 目录本身**；
- 先显示「能释放多少」，输入 **`Y`** 才真正删除；
- 结束后在桌面写 `TempClean_log.txt`。

> 想清更早的文件：管理员 PowerShell 里运行 `.\Clear-TempDirs.ps1 -Days 7`（默认会先预演并让你输入 Y 确认）。

### Parameters / 参数

| Parameter | Description / 说明 |
|---|---|
| `-Path <string[]>` | **Required.** One or more target directories. Accepts pipeline input. / 目标目录，可多个，支持管道 |
| `-WhatIf` | Dry run: report what would be deleted, delete nothing. / 预演，不实际删除 |
| `-Yes` | Do not prompt before deletion (sets `$ConfirmPreference='None'`). Use in non-interactive / `.cmd` launchers (where `-Confirm:$false` does not bind under `-File`). / 跳过确认，供非交互/启动器使用 |
| `-Confirm:$false` | Do not prompt before each deletion (works when calling the script directly from PowerShell). / 跳过逐个确认（直接从 PowerShell 调用时用） |
| `-StopUpdateService` | Stop `wuauserv`/`bits` before deleting, restart after. / 删除前停更新服务，结束后恢复 |
| `-LogPath <path>` | Log file. Default `%USERPROFILE%\Clean-StubbornDirs.log` / 日志路径 |
| `-Force` | Allow protected system paths (drive roots, `C:\Windows`, `Program Files`, ...). **Dangerous.** / 允许删受保护的系统路径，慎用 |

---

## How it works / 工作原理

对于每个目标目录：

1. **`takeown /f <dir> /r /d y`** — 递归把属主改为当前管理员，解决 "TrustedInstaller 拥有 → 拒绝访问"。
2. **`icacls <dir> /grant Administrators:F /t /c`** — 递归授予 Administrators 完全控制，解决权限不足。
3. **`Remove-Item -Recurse -Force`** — 递归删除。
4. 记录每个目录「删除前 / 删除后」体积，写入日志。

> 这三步是 Windows 上清理"管理员也删不掉"的顽固目录的通用做法，可套用到任意目录；脚本只是把它参数化、加了预演与安全保护。

---

## Safety guards / 安全保护

- **默认拒绝**受保护路径（`C:\`、`C:\Windows`、`C:\Windows\System32`、`C:\Program Files`、`C:\ProgramData`、`C:\Users`、用户主目录、任意驱动器根目录），除非显式 `-Force`。
- 支持 `-WhatIf` 预演；默认删除前有确认提示（`ConfirmImpact = High`）。
- 逐项目录日志，便于事后核对删了什么、释放了多少。

> 注意：保护是"精确匹配这些关键目录"，**不会**阻止删除它们下面的子目录（例如允许删 `C:\Windows\Temp`）。请仍自行确认路径。

---

## 实测记录 / Verified

测试环境：Windows 11 Pro (build 22631)，Windows PowerShell 5.1，普通用户令牌（未提权）。

| 测试项 | 方法 | 结果 |
|---|---|---|
| 语法检查 | `Parser::ParseFile` 解析脚本 | ✅ 通过，无语法错误 |
| 干跑 | 对测试目录执行 `-WhatIf` | ✅ 只打印 `WHATIF: would delete ...`，目录**保留未删** |
| 真实删除 | 对测试目录执行 `-Yes` | ✅ 目录被删除，日志记录 `OK ... freed=X MB` |
| 取消 | 启动器输入 `N` | ✅ 取消，目录**保留** |
| 受保护路径 | `-Path 'C:\Windows'` | ✅ 输出 `REFUSED (protected path)`，未删除 |
| 启动器 `.cmd` | 去掉提权段后喂入 `Y` / `N` 模拟 | ✅ `Y` 删除成功；`N` 取消保留 |
| 不可用参数 | `-File` 方式传 `-Confirm:$false` | ⚠️ 已知问题：`-File` 下 `$false` 绑定失败 → 已改用 `-Yes` + `-Command` 调用 |

> 说明：`C:\$WINDOWS.~BT`、`Windows.old` 等**系统目录需要管理员权限**。作者自动化环境无法弹出 UAC（安全桌面），因此**系统目录的最终删除请在桌面上双击启动器并点「是」提权执行**。仓库自带一个针对 `C:\$WINDOWS.~BT` 的独立一键脚本 `一键删除系统升级残留.cmd`：先试快速删除（`rd /s /q`），失败再 `takeown` + `icacls` 接管后重删，并在桌面写 `WindowsBT_delete_log.txt`。

## License

MIT — see [LICENSE](LICENSE). Provided **without warranty**; use at your own risk.
