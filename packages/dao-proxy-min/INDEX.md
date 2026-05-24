# dao-proxy-min · 工程总览 · 道法自然

**位**: `e:\道\道生一\一生二\Windsurf万法归宗\070-插件_Plugins\020-道VSIX_DaoAgi\dao-proxy-min\`

**当前版**: **v9.9.33** · 印 164 · 大道至简 · 一气化三清 · 损之又损 · 道法自然

**整日**: 2026-05-21 (重构整理 · 020目录归一) · 印 164 v9.9.33 (官方卸载全包·无固化) · 印 163 v9.9.31 (三清并行) · 印 160 v9.9.29 (终端会话池七层一招治)

---

## I · 主目结构 (2026-05-21 重构整理后 · 16 件 + 2 目)

```text
.
├── extension.js                                · 118 KB · ext-host 主入口 (v9.9.33 · 3044行)
├── package.json                                · 5.6 KB · 10 命令 · 4 配置
├── INDEX.md                                    · (本档) · 工程总览
├── LICENSE.txt                                 · Apache-2.0
├── .vscodeignore                               · vsce package 排除清单
│
├── dao-proxy-min-9.9.33.vsix                   · 135 KB · ★ 当前发行
│
├── install.ps1                                 · 13 KB · Windows 装脚 · 自检测端口
├── install.sh                                  · 9.8 KB · Mac/Linux 装脚
├── build_vsix.ps1                              · 9.4 KB · 打包脚 (vsce-free · .NET ZipFile)
│
├── _e2e_v9929_stress.ps1                       · 14 KB · 印 160 压力测试
├── _e2e_v9929_term.ps1                         · 9 KB · 印 160 e2e (命令面板 + HTTP 双路)
├── _test_v9929_term_pool.js                    · 16 KB · 印 160 单元测 · 15/15 PASS
│
├── REVERSE_DECONSTRUCTION_v9932_yin162.md      · 印 162 · 反向解构 · 终端互看非问题之论
├── TERMINAL_LEAK_ROOT_CAUSE_v9932.md           · 印 162 · 视野泄漏本源解构
│
├── media/
│   ├── icon.svg / icon.png                       · 道Agent 图标
│   └── webview-app.js                            · 「本源观照」面板
│
└── vendor/bundled-origin/                      · ★ 真本源
    ├── source.js                                 · 156 KB · proxy后台 · v9.4.5-tape · 字段级proto · invertSP
    ├── _silk_dao.txt                             · 9.0 KB · 帛书《老子》道经
    ├── _silk_de.txt                              · 11 KB · 帛书《老子》德经
    ├── _yinfu.txt                                · 1.7 KB · 道藏《阴符经》
    └── _origin_mode.txt                          · 6 B · 模式持存 (invert/passthrough)
```

---

## II · v9.9.29 之治 · 印 160 · 终端会话池 (2026-05-19)

**主公诏 (5/19 03:11)**: 「**专注于最本源最核心的终端问题 · 反者道之动 · 不依赖任何第三方 · 推进到底 实现一切**」

### 七层污染 · 一招治

| 层 | 病 | 真因 |
|---|---|---|
| ① OS cwd | 进程单例 | 共享一 shell |
| ② OS env | 继承可变 | 共享一 shell |
| ③ PTY | 字节流交织 | 共享一 shell |
| ④ Shell `%ERRORLEVEL%`/`$?` | 会话单例 | 共享一 shell |
| ⑤ IDE 终端池 | 复用 | 共享一 shell |
| ⑥ Agent 调用无状态 + 终端有状态 | 错配 | 共享一 shell |
| ⑦ 多 agent race | 抢 | 共享一 shell |

**真治** (反者道之动 · 弱者道之用):

每 agent 一独立 `cmd.exe`/`bash` 子进程 (`cp.spawn /k mode` · OS 进程级隔离)
+ stdin pipe 持续写
+ sentinel (RS+UUID) 包夹切片
+ `ver>nul` 重置 ERRORLEVEL

**零第三方** · 全 Node 内置 `child_process` · ~280 行新增 · `_test_v9929_term_pool.js` **15/15 PASS**.

### 三路调

| 路 | 用 | 端 |
|---|---|---|
| ① 命令面板 | 主公手控 · GUI | `dao.term.exec` / `dao.term.list` / `dao.term.close` |
| ② HTTP | agent 远调 · localhost only | `:12780~12829` (per-user FNV) `/term/exec` `/term/list` `/term/close` `/term/ping` |
| ③ ext.js 内调 | 本扩展自调 | `_ensureTermPool().exec(sid, cmd)` |

### 道义

- 四十「**反者道之动 · 弱者道之用**」— 反共享一终端 · 用 `child_process` 弱柔
- 六十一「**大邦下流 · 牝以靓胜牡**」— 每 sid 处下一 shell · 不争一终端
- 二十八「**朴散为器 · 圣人用则为官长**」— `spawn` 之朴 · 散为多 shell 之器
- 四十八「**损之又损**」— 零依赖 · 七层一招

---

## III · 真药全谱 (v9.7.0 → v9.9.29)

| 真药 | 版 | 治 | 位 |
|---|---|---|---|
| **A** | v9.7.6 / v9.2.0 | source.js · invertSP 字节级保 · H2 stream 三路监听 | source.js |
| **B** | v9.8.0 | setAnchor 同值不写 · 守一不离 | extension.js |
| **C** | v9.9.0 | 拨 source.js setInterval | source.js |
| **D** | v9.9.0 | proxyStart EADDRINUSE 1ping · 活复用死归直连 | extension.js |
| **E** | v9.9.0 | deactivate 不杀 LS · 上善若水 | extension.js |
| **F** | v9.9.0 | cmdInvert 不杀 LS | extension.js |
| **G-K** | v9.9.2 | 删 forceRestartLS / taskkill / 主动 reloadWindow 全废 | extension.js |
| **L** | v9.9.2 | 扩展 ID 自识 (`context.extension.id`) | extension.js |
| **M-N** | v9.9.14 | deactivate 自清锚 + dao.* 三键 Promise.allSettled | extension.js |
| **P+** | v9.9.15 | cmdPurge race 15s + 进度提示 | extension.js |
| **Q-S** | v9.9.13 | body>20KB skip · long-body 26-needle · maxDepth 3 | source.js |
| **复 9.9.13** | v9.9.16 | activate/deactivate 字符级复 9.9.13 之朴 (归根复命) | extension.js |
| **两经归一** | v9.9.20 | _silk_dao + _silk_de + _yinfu 加载 (帛书 + 阴符) | extension.js + source.js |
| **三诉同治** | v9.9.22 | 五层同治 (印 154) | extension.js |
| **软编码归一** | v9.9.25 | `SELF_EXT_ID` / `SELF_EXT_DIR_REGEX` 抽自 package.json · 适所有 fork | extension.js |
| **三招齐发** | v9.9.26 | deactivate ⑦ 强标 .obsolete + cmdPurge 末 reloadWindow + 三平台主进程退 | extension.js |
| **软编码彻终** | v9.9.27 | cmdPurge step 7/9 + deactivate 兜底 5 处全归一 (印 158) | extension.js |
| **detached cleanup spawn** | v9.9.28 | spawn detached child_process · 脱 ext-host / 主父子链 · 自卸自身本体 (印 159) | extension.js + 内嵌 _cleanup_spawn.js |
| **终端会话池** | **v9.9.29** | **七层污染一招治 · 每 agent 一独立 cmd.exe/bash · OS 进程级隔离 (印 160)** | **extension.js · ~280 行新** |

---

## IV · 软编码 · 适所有用户 / 所有 fork

| 维 | 适法 | 实证 |
|---|---|---|
| 用户名 | `os.userInfo().username` 动态 | extension.js (`forceRestartLS` USERNAME 过滤) |
| home 目录 | `os.homedir()` 跨平台 | extension.js (settings 路径 / .obsolete 路径 / .windsurf/extensions) |
| 配置基目录 | Win=`%APPDATA%` / Mac=`~/Library/Application Support` / Linux=`$XDG_CONFIG_HOME` 或 `~/.config` | extension.js `_settingsJsonPath()` |
| 端口分配 | `default: 0` · per-user **FNV-1a hash** · 8889..8988 (proxy) / 12780..12829 (term) | package.json + extension.js |
| 平台 LS 杀 | Win=`taskkill /F /FI` · Mac+Linux=`pkill -f` (含 `-u $uid`) | extension.js `forceRestartLS` |
| 平台主进程退 | Win=`wmic`+`taskkill /F /PID` · Mac=`ps`+`kill -9 Windsurf.app/MacOS/Windsurf` · Linux=`ps`+`kill -9 windsurf` | extension.js `cmdPurge` F 层 |
| OS 限制 | `package.json.os = ""` · 不限平台 | package.json |
| **扩展 ID 自识** | `SELF_EXT_ID` 抽自 publisher+name | extension.js (v9.9.25) |
| **目录前缀自识** | `SELF_EXT_DIR_REGEX = ^${SELF_EXT_ID}-` | extension.js (v9.9.25) |
| 端口冲突避让 | EADDRINUSE 不抢 · 1 ping 验 · 活复用 · 死归直连 | extension.js `proxyStart` |

**实证**: 主公若 fork 此 repo · 改 `package.json` 之 `publisher` / `name` (e.g. `myorg.dao-mini`) → **不改一行 .js** → 自身 .obsolete 标 / uninstallExtension 调 / deactivate 兜底 全部自适新 ID. 玄同 · 名实终一.

---

## V · 主公装/卸路径

### 装 (三路)

```powershell
# 路 1: install.ps1 (推荐 · 自动检测 · Win)
cd dao-proxy-min
.\install.ps1

# 路 2: GUI · 命令面板 → "Extensions: Install from VSIX..." → 选 dao-proxy-min-9.9.33.vsix

# 路 3: CLI
windsurf --install-extension dao-proxy-min-9.9.33.vsix --force
```

### 卸 (二路 · 全自治)

| 路 | 触发 | 内 |
|---|---|---|
| ① **dao.purge** (命令面板「了事拂衣去」) | 主公点 | F 段后 spawn detached cleanup → reloadWindow |
| ② **扩展面板 [✘]** (UI 卸 · CLI uninstall) | 主公手 | watchdog 监 onDidChange → self 不在 extensions.all → 立 spawn detached cleanup + reloadWindow (3s 后) |

**spawn detached cleanup 五招**:

1. sleep 2s — 等 ext-host 真死 + Windows 文件 lock 释放
2. rm 物理目录 — 扫 `<ext-dir>/<self-id>-*` → `fs.rmSync` (10 次重试)
3. patch `extensions.json` — 删 `<self-id>` 条目
4. patch `.obsolete` — 删 `<self-id>-*` 死标
5. kill `:8889~:8988` LISTENING utility — 三法查 cmdline + 兜底 kill

---

## VI · 验

```powershell
# 单元 · 终端会话池 (印 160)
node _test_v9929_term_pool.js
# 期: 15/15 PASS · 2 sid 隔离 · sentinel 包夹 · ver>nul 重置 · 多 agent race · pipe 持续写

# e2e · 命令面板 + HTTP 双路 (印 160)
.\_e2e_v9929_term.ps1
# 期: dao.term.exec/list/close 三命令通 · /term/exec/list/close/ping 四端通

# 装毕验 · /origin/preview 三 dot 全亮
# 1. 主公装 dao-proxy-min-9.9.29.vsix
# 2. 命令面板 → "道Agent: 启 (invert)"
# 3. 命令面板 → "道Agent: 浏览器观真 SP" → 浏览器开 /origin/preview
# 4. 期: 三 dot=Proxy✓ Capture✓ Mode✓ · 道魂 ~7237 字 (帛书《老子》+ 阴符)
```

---

## VII · 主公自决之退路

```text
若 v9.9.33 装即生效 → 期 ✓ · 「本源观照」三 dot 全亮 · 终端三命令可调
若仍诉问题 → 走 dao.purge (官方 [✘] + Reload Window) 净卸再装
若欲查印 160 之实证 → _test_v9929_term_pool.js · 15/15 PASS
若欲打包新版 → 改 package.json.version → .\build_vsix.ps1
若欲查历史VSIX → ../_归档/vsix_v9929-v9932/
若欲查印161备份 → ../_归档/bak_v9929_yin161/
```

---

## VIII · 道义结

> **大成若缺, 其用不敝; 大盈若盅, 其用不窘.** ——《四十五章》
>
> v9.9.29 · 终端池之大成 · 看似多一层 child_process 之缺 · 实则七层污染一招治, 万 sid 不争, 用之不敝.
>
> **反者道之动, 弱者道之用.** ——《四十章》
>
> 反共享 shell 之坚 · 用 spawn 之柔 · 反 fork API 不可信 · 用 detached 自治. 道之全用, 在反在弱.

---

**2026-05-21 · 重构整理毕** · 020目录归一 · dao-proxy-min-9.1.x-改良→dao-proxy-min · v9.9.33统一 · 旧版归档
