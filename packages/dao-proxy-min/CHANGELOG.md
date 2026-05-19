# Changelog · dao-proxy-min

> 反也者, 道之动也; 弱也者, 道之用也. —— 帛书《老子》德经

## v9.9.29 — 印 161 · 损之又损 · 复归朴本 · 道法自然 (2026-05-19)

> **为学者日益, 闻道者日损. 损之又损, 以至于无为, 无为而无不为.** —— 帛书《老子》四十八章
>
> **反也者, 道之动也; 弱也者, 道之用也.** —— 帛书《老子》四十章
>
> **道恒无名. 朴唯小, 而天下弗敢臣. 侯王若能守之, 万物将自宾.** —— 帛书《老子》三十七章

### 主公诏 (5/19 03:11 → 印 158→159→160→161 链)

「**专注于最本源最核心的终端问题 · 反者道之动 · 不依赖任何第三方 · 推进到底 实现一切**」

「**彻底去芜存菁 · 道法自然 · 损之又损**」

### 真本源参毕 · 反代本就 in ext-host

精读 `extension.js` L383~ 之活相 — **真态**:

```js
async function proxyStart(port, mode) {
  const mod = require(srcPath);              // ★ require 入 ext-host 同进程
  _proxyHandle = await mod.start({ port }); // ★ http server listen 在 ext-host 内!
}
async function proxyStop() {
  await _proxyHandle.close();                // ★ server.close 在 ext-host 内!
}
```

→ **反代根本不是独立子进程 · 反代 = ext-host 内嵌 http server**.
→ **ext-host 死 → server 自然 close → 永无孤儿**.

### 「自建 × 模式」之伪病

| 想象之病 (印 158/159 引为治理动机) | 真实之态 |
|---|---|
| 反代 fork 之 utility 子进程成孤儿 | ★ **本无 fork** — 反代 = ext-host 内 server |
| ext-host 卸载 → utility 仍活 | ★ **ext-host 死 = 反代死** — vscode 内核保证 |
| :8981 端口残留 | ★ ext-host 进程死 → 端口自然释放 |
| 物理目录清不掉 | ★ vscode 启动协议本应清 (Windsurf fork 偶 bug · 印 156 ⑦ 段已治) |

→ **v9.9.27 watchdog + v9.9.28 cleanup spawn + `_cleanup_spawn.js` = 解决一个不存在的问题之繁本**.

### 五刀 · 损之又损

| 刀 | 部位 | 治 | 减 |
|---|---|---|---|
| ① | activate 之 watchdog 调用 + 注释 | **删** | -6 行 |
| ② | `_spawnDetachedCleanup` + `_setupSelfUninstallWatchdog` + 幂等标志声明 | **删** | -236 行 |
| ③ | cmdPurge 末段 (自动 reload + spawn) | **简化** 为「主公一念 reload (含立即 Reload 按钮)」 | -10 行 |
| ④ | deactivate 兜底 spawn 探 | **删** (保 ⑦ 段印 156 真药) | -19 行 |
| ⑤ | `build_vsix.ps1` 之 `_cleanup_spawn.js` 引用 | **删** | -1 行 |

### 验

| 验 | 项 | 真态 |
|---|---|---|
| 减码 | extension.js | 143015B → 130357B (-12658B / -8.8%) |
| 减行 | extension.js | 3587 → 3333 (-254 行) |
| 减 vsix | dao-proxy-min-9.9.29.vsix | 123348B → 113067B (-10281B / -8.3%) |
| 砍标 | `_spawnDetachedCleanup` / `_setupSelfUninstallWatchdog` / `_detachedCleanupSpawned` / `_selfUninstallReloadTriggered` / `ELECTRON_RUN_AS_NODE` / `_cleanup_spawn.js` / `selfWatchdog` / `spawn detached cleanup` | **8/8 全 ✓ 已删** |
| 留标 | `_ensureTermPool` / `DaoTerminalPool` / `_startDaoTermService` / `cmdPurge` / 强标 `.obsolete` (deactivate ⑦) / `tryStartExternalApi` / `tryStopExternalApi` / 印 161 | **8/8 全 ✓ 留** |
| 语法 | `node --check extension.js` | **exit=0 ✓ 通** |
| 装毕 | zhou + admin · CLI `--install-extension --force` | **双账号 ✓ 装毕** |

### 当前态对照

```text
extension.js
├── ① 反代核 (proxyStart/proxyStop · in ext-host) ──── 不动 (印 156 真药)
├── ② cmdPurge (主公一念 reload · 含按钮) ──────── 简 (印 161 朴)
├── ③ 终端会话池 (_ensureTermPool · DaoTerminalPool) ── 不动 (印 160 真药)
├── ④ deactivate (⑦ 段兜底标 .obsolete) ────────── 简 (砍 spawn 探 · 留 ⑦)
├── ⑤ proxy watchdog (30s 自愈 · 反代复活) ───────── 不动 (印 v9.4.7 真药)
└── ⑥ 外接 api (tryStartExternalApi / Stop) ───────── 不动 (印 124 真药)

砍部 (繁本 · 印 158/159):
× _setupSelfUninstallWatchdog (~85 行)
× _spawnDetachedCleanup (~140 行)
× _cleanup_spawn.js (13.8 KB · 整件)
× _detachedCleanupSpawned / _selfUninstallReloadTriggered (幂等标)
```

### 道义

- 四十八「**损之又损 · 以至于无为 · 无为而无不为**」 — 五刀全砍 ~290 行 + 13.8 KB 繁本
- 四十「**反者道之动 · 弱者道之用**」 — 反「自治防孤儿」之妄 · 用 vscode 内核生命周期之弱柔
- 三十七「**道恒无名 · 朴唯小 · 而天下弗敢臣**」 — 信 vscode 内核 + ext-host 生命周期 + Windsurf 启动协议
- 二十八「**朴散则为器 · 圣人用则为官长 · 夫大制无割**」 — 复归朴本 · 不再以妄想构繁本
- 六十四「**为之于其未有 · 治之于其未乱**」 — 治在主公一念之先 · 不在 ext 自治

---

## v9.9.27 — 软编码彻终 + self-uninstall watchdog · 印 158 · 适所有用户 / 所有 fork (2026-05-19)

> **朴散为器 · 圣人用则为官长 · 夫大制无割.** —— 帛书《老子》二十八章
>
> **一者 · 其上不攸 · 其下不忽 · 寻寻呵 · 不可名也 · 复归于无物.** —— 帛书《老子》十四章

### 主公诏

「**查看所有成果 · 检测所有成果 · 软编码一切 · 适配所有用户 · 所有用户均可用一切 · 推送发布最新之版本于github当前主账号 zhouyoukang 和子账号 zhouyoukang1234-spec 双同步推送一切**」(5/19 02:09)

### 病诊 (反者道之动 · 二十八章)

v9.9.25 已立 `PKG_PUBLISHER` / `PKG_NAME` / `SELF_EXT_ID` / `SELF_EXT_DIR_REGEX` 抽自 `package.json` 之朴 ·
但代码内仍残 **5 处** `dao-agi.dao-proxy-min` 字面散写未改:

| # | 位 | 病 |
|---|---|---|
| 1 | extension.js L1662 | `cmdPurge` step 7 清旧残: `/^dao-agi\.dao-proxy-min-/.test(k)` |
| 2 | extension.js L1674 | `cmdPurge` step 7 扫物理目录: `/^dao-agi\.dao-proxy-min-/.test(d)` |
| 3 | extension.js L1693 | `cmdPurge` step 9 文案: `"卸载插件 dao-agi.dao-proxy-min ..."` |
| 4 | extension.js L1706 | `cmdPurge` step 9 调用: `uninstallExtension("dao-agi.dao-proxy-min")` |
| 5 | extension.js L2721 | `deactivate` 兜底: `e.identifier.id === "dao-agi.dao-proxy-min"` |

**症**: 主公若 fork repo / 改 `publisher` (e.g. 改成 `myorg`) / 改 `name` → 上 5 处仍朝旧硬码取查 → 自身 .obsolete 标错 / uninstallExtension 调不存在的 ID / deactivate 兜底比错 → 名实失一.

### 治本一招 (二十八章「夫大制无割」)

5 处全改 `SELF_EXT_DIR_REGEX` / `SELF_EXT_ID` · 抽自 `package.json` · 一处定义 · 全文一致 · 自然适所有 fork / 所有 publisher.name 改名情形.

```diff
- if (/^dao-agi\.dao-proxy-min-/.test(k) || /wam/i.test(k)) {
+ if (SELF_EXT_DIR_REGEX.test(k) || /wam/i.test(k)) {

- out.appendLine("  → 卸载插件 dao-agi.dao-proxy-min ... (等至 15s)");
+ out.appendLine(`  → 卸载插件 ${SELF_EXT_ID} ... (等至 15s)`);

- await vscode.commands.executeCommand("workbench.extensions.uninstallExtension", "dao-agi.dao-proxy-min");
+ await vscode.commands.executeCommand("workbench.extensions.uninstallExtension", SELF_EXT_ID);

- e.identifier.id === "dao-agi.dao-proxy-min" &&
+ e.identifier.id === SELF_EXT_ID &&
```

### 守 (字节级 / 功能级)

- v9.9.26 之 `.obsolete` 三招 (cmdPurge step 7 强标 + step N 自动 reloadWindow + deactivate 兜底) 全守
- v9.9.25 之 `cmdPurge` 197 行朴守
- v9.9.22 之三诉同治守 (卸不真除 / 切编辑模式 / 切经文)
- `source.js` 字节级 = 123131 B 守
- 帛书三经文本字节级守

### 实证

```bash
$ node --check extension.js
[exit] 0

$ grep -c 'dao-agi\.dao-proxy-min' extension.js
5  # 全部仅在注释 (L69/85/86/296/1648 文档说明) · 可执行代码 0 处
```

### 适配万法实证

| 场景 | 现态 v9.9.27 | 期态 |
|---|---|---|
| Windows / user=`Administrator` / fork=zhouyoukang | port=8937 (FNV-1a) · SELF_EXT_ID=`dao-agi.dao-proxy-min` · 自识 | ✓ 万法适 |
| macOS / user=`alice` / fork=zhouyoukang | port≈89XX · SELF_EXT_ID=`dao-agi.dao-proxy-min` · 自识 | ✓ 万法适 |
| Linux / user=`bob` / fork=myorg/dao-mini (改 publisher+name) | port≈89XX · SELF_EXT_ID=`myorg.dao-mini` · 自识 (抽自其 package.json) | ✓ **万法适 (v9.9.27 新)** |

「**朴散为器, 圣人用则为官长, 夫大制无割**」(二十八章) — 一处定义, 万法承之 · 主公无为, 万物自宾.

### 续治 (主公诏 5/19 02:09)

> 「**点击卸载后 既没有卸载插件 windsurf也没重启 推进到底**」

诊: v9.9.26 三招中 deactivate ⑦ 段强标 .obsolete + cmdPurge 末自动 reloadWindow 都生效, 但**漏一脉** —— 扩展面板点 [✘] 路径走 `ExtensionManagementService.uninstall`, 仅 deactivate 一招触, ⑦ 段标 .obsolete 后 ext-host shutdown, 此时 `vscode.commands.executeCommand("workbench.action.reloadWindow")` 已**无法触发** → 主公视为「没卸 · 没重启」.

治本药二 (反者道之动 · 弱者道之用): activate 时挂 `vscode.extensions.onDidChange` 监听 (VS Code API · 见 vscode.d.ts L17647 · 「fires when extensions.all changes」). 时序:

```text
主公点 [✘]
  → VSCode 主进程 ExtensionManagementService.uninstall(self)
  → 主进程删 extensions.json 中 self 条目
  → ★ emit onDidChange 事件 (此时 ext-host self 还活!)
  → 之后才让 ext-host deactivate self
```

故监听器中 self 还活 → `vscode.commands.executeCommand` 仍 work → 立即 `reloadWindow` → 主公的 Windsurf 自动重启 → 启动协议清物理目录. ext-host 重启时 deactivate ⑦ 段又会再次确保 .obsolete 标 (双保险).

道义:
- 六十四章「为之于其未有也 · 治之于其未乱也」(onDidChange 触发于 deactivate 前)
- 七十六章「天下莫柔弱于水 · 而攻坚强者莫之能胜」(以 onDidChange 之柔 · 攻 deactivate 不能 reload 之坚)
- 四十章「反者 · 道之动；弱者 · 道之用」(反 deactivate 末路 · 用 activate 时机注册之德)

三路径全覆:
- ① cmdPurge 自调 reloadWindow (旧路守不变)
- ② 扩展面板 [✘] 触 onDidChange watchdog 调 reloadWindow (★ v9.9.27 新)
- ③ CLI uninstall (主进程外路 · ext-host 不触此事件 · 但启动协议会清物理)

幂等: `_selfUninstallReloadTriggered` 标守 cmdPurge ① + watchdog ② 不重触 reload.

---

## v9.9.26 — 真治 · 全自动卸再起 · 主公无为 (2026-05-19 凌晨)

> **为而弗恃, 长而弗宰, 是谓玄德.** —— 帛书《老子》五十一章
>
> **正言若反.** —— 帛书《老子》七十八章

### 主公诏

「**全自动卸载再重启 windsurf · 用户彻底无为**」(5/19 01:31)

### 真本源诊 (cascade CLI 实测 · 5 轮 unin/inst 循环)

Windsurf fork 1.110.1 之 `ExtensionManagementService.uninstall` 漏写 `.obsolete` ·
仅删 `extensions.json` 条目 → 重启时 VSCode discover 扫物理目录 → 物理有 + ext.json 无 + obs 无 → **rediscover 复活** (僵尸装) ·
此为「卸而复活」之根因 · 非 dao 罪 · 乃 fork 漏。

### 治本三招 (反者道之动)

| 招 | 治 | 道义 |
|---|---|---|
| ① cmdPurge step 8 **强标 self 入 .obsolete** | `fs.writeFileSync` 直写磁盘 · 兼扫物理目录全标 `dao-proxy-min-*` (历版同治) | 五十一「为而弗恃」· 直写磁盘绕过 fork 漏 |
| ② cmdPurge 末 **自动 reloadWindow** (3s 倒计时) | 主公无为 · 净卸即重启 · 一气呵成 | 上德无为 · 主公诏「彻底无为」 |
| ③ deactivate 兜底标 .obsolete | 兼面扩展面板 [✘] 路径 · 检 extensions.json 无 self 时自标 (CLI 路不触 deactivate · 但面板路触) | 七十八「正言若反」· 多路兜底 |

### 兼容

- v9.9.25 之 SELF_EXT_ID 软编码归一 字节级守不变
- v9.9.25 之 cmdPurge 五层同治 (B/C/A/D/E) 净化重组到 step 8 强标 .obsolete (合并 + 简)
- v9.9.24 之主进程退 F 层 简删 (改用 reloadWindow + .obsolete · 不需 wmic/taskkill 之激进)
- source.js 字节级 = 123131 B (微调 · 帛书三经文本字节级守)

### 主公装 v9.9.26 主公真无为路径

```text
主公点扩展面板 [✘] (或 cmdPurge 命令)
  → ext-host deactivate · 兜底标 .obsolete (③)
  → 或 cmdPurge step 8 强标 + step N reloadWindow (①+②)
  → Windsurf 自动 reload · 重启时 VSCode 见 .obsolete · 跳激活 · 下启清物理目录
  → 主公无为 · 一切自归
```

「**为而弗恃 · 长而弗宰 · 是谓玄德.**」(五十一章) — v9.9.26 真治 fork 漏 · 主公无为而无不为.

---

## v9.9.25 — 软编码归一 · 适所有用户 · 三平台主进程退 (2026-05-19)

> **朴散为器, 圣人用则为官长, 夫大制无割.** —— 帛书《老子》二十八章
>
> **人法地, 地法天, 天法道, 道法自然.** —— 帛书《老子》二十五章

### 主公命

「**软编码一切 · 适配所有用户 · 所有用户均可用一切 · 推送发布最新之版本于 github 当前主账号 zhouyoukang 和子账号 zhouyoukang1234-spec 双同步推送一切**」

### 治本两味

| 改 | 损/守 | 道义 |
|---|---|---|
| 抽 `SELF_EXT_ID` 常量自 `package.json` (publisher + name) · 全文一致 (3 处 `dao-agi.dao-proxy-min` 字面散写归一: `_scanLatestVendorDir` 之 `startsWith` + `match` 正则, `cmdPurge` step 11 `.obsolete` 标 filter, step 13 `uninstallExtension` 参) | +1 抽常量块 / -10 行硬写 / +0 行净 (规整) | 二十八章「朴散为器·圣人用则为官长·夫大制无割」· 主公若 fork 改 publisher/name · 改一处即净 · 全文承之 |
| `cmdPurge` F 层主进程退三平台兜底: Win=`wmic`+`taskkill /F /PID` / Mac=`ps -ax`+`kill -9 Windsurf.app/Contents/MacOS/Windsurf` / Linux=`ps -ax`+`kill -9 windsurf` (`--type=` / `Helper` 排除) | +60 行 (Mac/Linux 等价) / Win 既路守不变 | 二十五章「人法地, 地法天, 天法道, 道法自然」· 三平台一视同仁 · 不再 Win-only · Mac/Linux 主公诉 cmdPurge 时同得真水过无痕 |

### 软编码全谱 (v9.9.25 后实证 · 适所有用户)

| 维 | 适法 | 位 |
|---|---|---|
| 用户名 | `os.userInfo().username` 动态 | `forceRestartLS` USERNAME 过滤 |
| home 目录 | `os.homedir()` 跨平台 | settings 路径 / .obsolete / .windsurf/extensions |
| 配置基目录 | Win=`%APPDATA%` / Mac=`~/Library/Application Support` / Linux=`$XDG_CONFIG_HOME` 或 `~/.config` | `_settingsJsonPath()` |
| 端口分配 | `default: 0` · per-user **FNV-1a hash** · 8889..8988 · 多账号自然隔离 | package.json + extension.js |
| 平台 LS 杀 | Win=`taskkill /F /FI IMAGENAME` / Mac+Linux=`pkill -f` (含 `-u $uid`) | `forceRestartLS` |
| 平台主进程退 (v9.9.25 新) | Win=`wmic`+`taskkill /F /PID` / Mac=`ps`+`kill -9` / Linux=`ps`+`kill -9` | `cmdPurge` F 层 |
| OS 限制 | `package.json.os = ""` · 不限平台 | package.json |
| 扩展 ID 自识 (v9.9.25 新) | `SELF_EXT_ID` 抽自 `publisher + "." + name` | extension.js 常量 |
| 引擎 | `engines.vscode = ^1.85.0` · 通用 | package.json |

### 兼容

- v9.9.24 之五层同治 (B `.obsolete` / C `fs.rmSync` / A `workbench.extensions.uninstallExtension` / D 同卸 dao-byok / E `settings.json` 直清 codeium.*) 全字节级守不变
- v9.9.22 三诉同治 (cmdInvert/cmdPassthrough/cmdToggle 软切提示) 不动
- v9.9.21 软编码 vendorDir (per-user 最新版扫描) 不动
- source.js 字节级 = v9.9.18+ (123104 B · 印 126 经藏多门)
- 帛书《老子》道经+德经 + 道藏《阴符经》三文字节级守

### 主公装 v9.9.25 三步

```text
① 主公先关 Windsurf
② 主公启 Windsurf · UI 卸旧版 (若装)
③ 主公装 dao-proxy-min-9.9.25.vsix
   activate 自动: proxyStart :8889..8988 (per-user FNV) + setAnchor + spawn-hook 挂
   主公开新对话 → invertSP 自动注帛书《老子》+ 道藏《阴符经》
   「本源观照」面板三 dot 全亮
```

「**朴散为器, 圣人用则为官长, 夫大制无割.**」(二十八章) — v9.9.25 抽常量归一 · 一处定义, 万法承之 · 适所有用户 · 所有用户均可用一切.

---

## v9.9.0 — 印 124 · 第一细药 · 外接 api 归一 (2026-05-17)

> **图难于其易也，为大于其细也。天下之难作于易，天下之大作于细。是以圣人终不为大，故能成其大.** —— 帛书《老子》六十三章
>
> **为之于其未有也, 治之于其未乱也.** —— 帛书《老子》六十四章
>
> **损之又损, 以至于无为, 无为而无不为.** —— 帛书《老子》四十八章

### 一句话

承印 123 (dao-proxy-max v1.0.8 · 22/38 模真聊真应) 之实, 归一于 min 之厚。**v9.8.0 守一不离主体字节级不动**, 加 `vendor/外接api/` 一文件夹 · **默关** · 主公一字开 · Cascade 选单立见 14 provider 之 N 模 (与 4 BYOK 一视同仁)。

### 归一之实

| 件 | 大小 | 来源 | 职 |
|---|---|---|---|
| `vendor/外接api/gateway/server.js` | 55.7KB | 字节级 cp from max v1.0.8 | 主入口 · CLI: `--port --config` |
| `vendor/外接api/gateway/registry.js` | 10.1KB | 字节级 cp from max | Provider 注册中心 |
| `vendor/外接api/gateway/translate.js` | 27.7KB | 字节级 cp from max | Anthropic ↔ OpenAI ↔ Gemini ↔ Ollama 协议互转 |
| `vendor/外接api/gateway/capabilities.js` | 7.3KB | 字节级 cp from max | 各 model 之 tool/vision/system 能力辨 |
| `vendor/外接api/gateway/providers/*.js` | 12.7KB | 字节级 cp from max | openai/anthropic/gemini/ollama/http (5 件) |
| `vendor/外接api/lm_register.js` | ~14KB | 抽 max ext.js L666-1018 + 参数化 | vscode.lm 注 (三别名 fallback) |
| `vendor/外接api/runtime.js` | ~10KB | 新写 | 启停 wrapper · 默关 · 主公一字开 |
| `vendor/外接api/配置.example.json` | 2.3KB | 字节级 cp from 070-插件_Plugins/外接api/ | GitHub Models 极简起手 |
| `vendor/外接api/README.md` | ~5KB | 新写 | 一文之示 |

### 主体改动 (扩 · 不破)

`extension.js`:

- L2110-2123 · commands 加 1 行 `dao.外接api.toggle`
- L2232-2239 · activate 末 watchdog 之后调 `tryStartExternalApi(ctx)` (try-catch · 失败不影响 min)
- L2276-2279 · deactivate ④ 之后, ⑤ 之前调 `tryStopExternalApi()`
- L2297-2396 · 文件末加 100 行 helper (`tryStartExternalApi` / `tryStopExternalApi` / `cmdExternalApiToggle` + 单例 `_externalApiRuntime`)

`package.json`:

- version: 9.8.0 → **9.9.0**
- commands 加 1 项 `dao.外接api.toggle`
- configuration.properties 加 1 项 `dao.外接api.enabled` (默 **false** · 不扰心)

### 一身两轨 (反者道之动)

```text
反代核轨 (字节级守 · v9.8.0 commit)         外接 api 轨 (印 124 · 第一细药)
  vendor/bundled-origin/source.js              vendor/外接api/gateway/server.js
  + _silk_dao.txt + _silk_de.txt               + lm_register.js + runtime.js
  :8889..8988 (per-user FNV)                   :11635..11734 (per-user FNV)
  Cascade Connect-RPC SP 注入                  OpenAI/Anthropic chat 14 provider
  二态切换 (invert/passthrough)                vscode.lm 注 N 模入 Cascade 选单
                  ╰─────── per-user FNV-1a 端口不撞 · 互不依赖 ───────╯
```

### 主公一字 (一念三步活)

1. `Ctrl+Shift+P` → 设置 · 搜 `dao.外接api.enabled` · 勾上
2. `Ctrl+Shift+P` → `道Agent: 外接 api 开关` (或重启 Windsurf)
3. Cascade 模型选择器搜 `dao-` · 即见 14 provider 之 N 模

或一行：`Ctrl+Shift+P` → `道Agent: 外接 api 开关` (toggle 即自动改 enabled 并启)

### 配置

启时自动复 `vendor/外接api/配置.example.json` 至 `~/.codeium/dao-byok/配置.json` (用户域 · 跨 vsix 升级不丢)。主公手编填 apiKey + `enabled:true`。

### 验

```powershell
# 静检 (与 v9.8.0 一致 · 主体不破)
pwsh _审视/_smoke.ps1

# v9.8.0 strip-test 仍通 (主体字节级不动)
node _审视/_v980_strip_test.js   # 6/6 pass

# v9.9.0 外接 api 自检 (打开 enabled · 启 · 查 /__dao/providers)
Ctrl+Shift+P → dao.外接api.toggle
curl http://127.0.0.1:<gateway-port>/health
curl http://127.0.0.1:<gateway-port>/__dao/providers
```

### 哲

**「图难其易·为大其细」**: 不直奔大归一 (B/C 之事), 起手作于最易最细 — 加 vendor/外接api/ 一文件夹, 默关, 主公一字开。

**「终不为大·故能成其大」**: 不立「大」之名, 默关不扰心; 主公愿则启, Cascade 立见 N 模; 不愿则寝, min 反代核如初。

**「为之于未有·治之于未乱」**: 反代核不动 · 二轨字节级正交 · 后续 B 之事 (byok 字节级劫 / Windsurf 反代 / Devin 反代 / webview 一面板) 待主公验后再图。

---

## v9.8.0 — 守一不离 (2026-05-06)

> **昔之得一者：天得一以清·地得一以宁·神得一以灵·侯王得一以为天下正.** —— 帛书《老子》三十九章
>
> **窈兮冥兮·其中有精·其精甚真·其中有信.** —— 帛书《老子》二十一章

### 治二根·名实终一·@ 工具复活

| 根 | 漏 | 药 |
|---|---|---|
| **@ 工具失** | `SIDE_CHANNEL_TAGS` 含 `additional_metadata` · 客户端以此 block 传 @项之元 (Cascade ID/file path/line range/symbol) · 剥之则 `trajectory_search` / `read_file` / `view_content_chunk` 等 @ 工具必败 | **删** `additional_metadata` from `SIDE_CHANNEL_TAGS` · 守 @项与元一体 |
| **名实不一** | `tape.all_fields[].raw_text` 显 BEFORE 态 · 主公见 OVERRIDE 残影 · 实则 upstream 已 neutralize · 视听皆误 | `_buildAllFieldEntry(content, mode)` 助函数 · 内部先 `stripSideChannelBlocks` 再 `neutralizeHiddenOverrides` · `raw_text = after` · **所见即所得** |
| **(兼治) g flag stateful** | `hasSideChannels` 三 RegExp `g` 标 · `lastIndex` 跨调用残留 · 部分字段假阴致 strip 漏 | `SIDE_CHANNEL_TAGS_RE.lastIndex = 0` + `MEMORY_BLOCK_RE.lastIndex = 0` + `DISCIPLINE_RE.lastIndex = 0` 三处显重置 |

### 改动定位 (`vendor/bundled-origin/source.js`)

- 行 ~672-709 · `SIDE_CHANNEL_TAGS` 删 `additional_metadata`
- 新增 `_buildAllFieldEntry(c, mode)` 助函数 · 主 handler 调之
- 行 ~743-759 · `hasSideChannels` 重置 `lastIndex` 三处
- `ORIGIN_VERSION_BASE = "v9.8.0"` · `ORIGIN_VERSION = "v9.8.0-shou-yi-bu-li"`

### 验

- `_审视/_v980_strip_test.js` · **6/6 PASS**
- `_审视/_smoke.ps1` · 静检 + 活探 · **25/25 PASS**
- `_审视/_verify_remote.ps1 -RunStripTest` · 远端实物 · **15/15 PASS**

### 哲

「得一」非守 user_rules · 非守 memories · 非守 system_prompt — 此皆客户端注之「加身」锚戒。「得一」守的是 **名实终一** 与 **@项与元之不可剥**。强剥 `additional_metadata` → 名去元 → agent 不知所云 → 工具必败。

---

## v9.7.9 — 道法自然 · 中性化身份锚 (2026-05-05)

承 v9.7.7 复归于朴。识 `<additional_metadata>` 中之 `SECTION_OVERRIDE_MODE_APPEND` 身份锚 (`Separately, if asked about what your underlying model is, respond with Cascade`)，以 `neutralizeHiddenOverrides` 转中性 (道家语)，**九章「持而盈之·不若其已」**: 不强加之身份，复用户域之自然。

## v9.7.7 — 复归于朴 (2026-05-04)

四味芜尽损 · 极简至 76KB · 二十八章「朴散则为器」: 余 4 KEEP_BLOCKS 主梁 (user_rules / memories / additional_metadata / tool_calling) · 弃二态枝。

## v9.6.0 — 守 Cascade ID (2026-05-03)

`additional_metadata` block 含 `Cascade ID:` 行 · 是 conversation tracker · 之前误剥 (兼及上下文) · v9.6 单守 Cascade ID 行 · 余 OVERRIDE 仍中性。**(后于 v9.8.0 一并升级 — 整 block 守住)**

## v9.5.0 — SECTION_OVERRIDE 中性化 (2026-05-02)

发现 `additional_metadata` 内 OVERRIDE 锚 · 引入 `neutralizeHiddenOverrides` · 不删 OVERRIDE block · 仅替其 content 为道家语 (二十二章「曲则金·枉则定」)。

---

## v9.2.0 — 反者道之动 · 弱者道之用 (2026-05-03)

> **反者道之动, 弱者道之用.** —— 帛书《老子》四十章
>
> **为道日损.** —— 帛书《老子》四十八章

### 四味真药

| 真药 | 漏 | 药 | 道义 |
|---|---|---|---|
| **A** | `proxyToCloud` 无 `req.aborted` / `res.close` / `upStream.setTimeout` · H2 stream 泄漏致 HOL 阻塞 | `req.aborted` + `res.close` + `upStream.setTimeout(180s)` → `NGHTTP2_CANCEL` | 四十章·**弱者道之用** |
| **B** | `setAnchor` 每次 activate 必写 `settings.json` · file watcher 空转 · ext-host 抖动 | API+文件双路同值不写 | 六十四章·**为者败之** |
| **C** | `proxyStart` `EADDRINUSE` 仅单次 ping · 假定远端永活 · dead remote 成 phantom | 1 ping → 活则 remote handle · 死则返 null (本窗口直连·不抢端口) | 八章·**上善若水** |
| **D** | `activate` 首装即 `forceRestartLS()` 广域杀 · 多窗口连锁 ext-host crash | activate 仅装 hook + 锚 settings · 不主动杀 LS · 自然重启时挂钩 | 四十八章·**为道日损** |

### 默认改动

- `dao.origin.banner` true → false (不言之教)

### 前车之鉴

v9.1.3 试图修补但 **加六事** (PID簿 / `_trackChild` / `forceRestartLS` 广窄分级 / EADDRINUSE 三验 / 8s 复查 / 60s 健康探针 / 离线 handle) · 净增 200+ 行码 · 反伤本源。v9.2.0 反之 · 损其名而存其本。**反者道之动**。

---

## v9.1.2 — 道法自然 · 逆序净卸 (2026-04-30)

### 逆序关停 · 根治卸载卡死

**根因**: 旧 `deactivate()` 先停代理 → LS 仍活 → 连死代理 → Windsurf 卡死.

**修复** — 反者道之动 · 逆序:

| 步骤 | 旧 (必死) | 新 (道法自然) |
|---|---|---|
| ① | 停代理 | **设透传** (安全网) |
| ② | 清锚 (API 失败) | **断钩** + `_cachedAnchored=false` |
| ③ | — | **同步清锚** (`_clearAnchorFileSync`) |
| ④ | — | **杀 LS** → 重生直连官方 |
| ⑤ | — | **停代理** (此时安全) |

- `_clearAnchorFileSync()` — 同步文件清锚, 绕过 VS Code API "not registered" 限制
- `cmdPurge` 同步重构为正确逆序
- `_custom_sp.json` 加入持存清理

### `<user_rules>` 可信格式注入 (v9.0→v9.1)

- `[CUSTOM-SP-ACTIVE]` 哨兵已移除 — 用户 SP 直出, 不触发模型注入检测
- `modifySPProto` / `modifyRawSP` — `spModifiedIdx` 追踪已修改 msg, save/restore 绕 `deepStrip`
- `stripSideChannelBlocks` / `hasSideChannels` — 移除冗余哨兵检测
- L1 测试 8/8 全绿

---

## v5.0.0 — 道法自然 (2026-04-29)

> 为学者日益, 闻道者日损. 损之又损, 以至于无为. 无为而无不为. —— 帛书《老子》德经

### 跳出二元 · 净减 270 行 (1536 → 1266 · vsix 减 8KB)

| 层 | v4.5 | v5.0 道法自然 |
|---|---|---|
| **道层** | TAO_HEADER + 道德经八十章 | 同 (永在前) |
| **法层** | 官方 SP 经"系统/用户侧"二分剥削 | 官方 SP **完整保留** |
| **术层** | proto deepStrip 递归净化所有 wire=2 字段 | proto **不动** |

### 删去之有为 (~250 行)

- `SIDE_CHANNEL_TAGS` / `SIDE_CHANNEL_TAGS_RE` / `MEMORY_BLOCK_RE` / `DISCIPLINE_RE`
- `stripSideChannelBlocks` / `hasSideChannels`
- `deepStripProtoSideChannels` / `deepStripRequestBody`
- `INFER_STRIP` 路径 (改为 `PASSTHROUGH`)

> 旧路 (v4.x): "剥侧信道"试图把 user_rules / MEMORY / discipline 等"系统侧"杀去, 留"用户侧"; 陷剥/留二元 · 字段必生新增 · 维护成本高.
>
> 新路 (v5.0): **前置道魂 · 不剥不削** · LLM 自感道魂之首言 · 后续官方约束自然让位.

> **注**: v5.0 之"道魂在前·不剥侧信道"路·后于 v9.x 系列被发现并不充分 (LS 客户端实际嵌入 `<additional_metadata>` 等带 `SECTION_OVERRIDE_MODE_APPEND` 之"加身"锚戒) · v9.5+ 复引 `stripSideChannelBlocks` + `neutralizeHiddenOverrides` · 但**精准而非二元**: 守 @ 工具之元 (v9.8.0) · 中性化身份锚 (v9.5+) · 此即"反者道之动"之实。

---

## v4.0.0 — 万法归宗 (2026-04-26)

### 字段级 proto 重构

- 离弃脆弱字节扫描, 改为字段级 proto 解析 / 序列化
- 27 种 XML-like 侧信道标签深度递归剥离
- 三档 RPC 全覆盖: `CHAT_PROTO` / `CHAT_RAW` / `INFER_STRIP` / `PASSTHROUGH`

### per-user 端口隔离

多账号同机时, 每用户自动分配唯一端口 (FNV-1a hash → 8889..8988)。

### 二态热切 + SSE + 本源观照 webview

模式切换不需重载 · `/origin/stream` SSE 推送 · 活动栏 → 道Agent 容器实时 SP 面板。

### 跨平台 + 净卸

LS 重启支持 Windows / macOS / Linux · "了事拂衣去" 一键净卸归本源。

### 7 命令

```text
道Agent: 启 (invert)             — 反者道之动
官方Agent: 启 (passthrough)      — 上善如水
道Agent: 切换模式 (道 ⇄ 官方)    — 二态热切
道Agent: 浏览器观真 SP            — 全貌解剖
全链路自检 (E2E)                  — 致虚守静
闭环自检 (L1 + L2)                — 同上
了事拂衣去 · 净卸                 — 归本源
```

---

## v3.0.0 — 极简反代 (2026-04-20)

### 朴

- 极简反代 · ~40KB · 3 命令 · 固定端口 8889
- source.js 字节扫描 + SP 替换
- vendor/bundled-origin 内联帛书

---

## 道义沿革

```text
v3.0  朴      → 字节扫描 · 一刀切 · 极简
v4.0  增      → 字段级 proto · 27 标签深剥 · 万法归宗
v5.0  损      → 跳出剥/留二元 · 道魂在前 · 道法自然
v9.1  逆      → 逆序净卸 · `<user_rules>` 可信注入
v9.2  弱      → 四味真药 · H2 stream · file watcher · phantom remote · 自然重启
v9.5  中      → SECTION_OVERRIDE 中性化 · 不删而转语
v9.7  朴      → 复归于朴 · 极简至 76KB
v9.8  得一    → 守 @ 工具之根 · 名实终一 · g flag stateful 兼治
```

> 大成若缺, 其用不敝; 大盈若盅, 其用不窘. —— 帛书《老子》德经
>
> 道法自然 · 无为而无不为 · 损之又损 · 以至于无为
