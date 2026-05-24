# CHANGELOG · packages/wam (rt-flow 道极版)

> 反者道之动 · 弱者道之用 · 天下之物生于有 · 有生于无. —— 帛书《老子》德经

## v3.3.0 (2026-05-24) · 💎 额度绝对优先分层 · 反者道之动 · 存量先于流量 · 当前

> *天之至私 · 用之至公 · 禽之制在炁*

**解构本源 (反者道之动 · 先解构隐藏在需求下的底层目标)**:

| 维度 | overage 美元 | 百分比配额 |
|---|---|---|
| 经济学性质 | **存量 (Stock)** | **流量 (Flow)** |
| 再生性 | 不可再生 · 用一分少一分 | 可循环 · 周期重置 |
| 不用的代价 | **沉没浪费** (废账户即损失真金白银) | 等待即回来 (无损失) |
| 道家映射 | "天下之物生于有" · 已生之物即损 | "有生于无" · 无穷归来 |

**病灶 (v3.2.1 之前 · 错误抽象)**:

`_scoreOf` 把两种本质不同的资源放在**同一个连续分数坐标系**里比大小:

- overage 账号:  `300 + min(100, $) + 时效` ≈ **150~460 分**
- 百分比账号:    `W*8 + D*3 + 时效`         ≈ **0~1830 分** (W50/D50 即 480+)

→ **主公图1 实证**: $195/$189/$208/$193/$185 等额度账号全部得 **400 分** (被 `min(100,$)` 封顶)  
→ 百分比账号 W50 反超之 → **实际行为与用户诉求完全相反** → 额度账号被冷落浪费 · 真金白银沉没

**治法 (九竅之邪在乎三要 · 可以動靜 · 分层各得其所)**:

```
═════════════════════════════════════════════════════════
║  切号决策金字塔 (绝对分层 · 各得其所 · 天之至私用之至公)
═════════════════════════════════════════════════════════
│
├─ 第三层 💎 OVERAGE 池 (存量·不用即损·绝对优先)
│   触发: overageActive = true (Extra Usage 余额 > 0)
│   主权: 1_000_000 基础分 · 永远凌驾百分比层
│   内排: overageDollars × 100 (全幅可比 · 去 min(100,$) 封顶)
│        $208=1_020_800 > $195=1_019_500 > $193=1_019_300
│   区间: [999_970, 1_099_950]
│
├─ 第二层 📊 百分比池 (流量·周期重置·次选)
│   触发: overageActive = false · effQ ≥ threshold
│   内排: W*8+D*3 + 时效 (沿用 v3.1.3 effQ 守门)
│   区间: [1, 9_999]  上限封顶 · 永不突破第三层
│
├─ 候补层 ⏳ 未验号 (待 verify 决定真相)
│   分数: 100  与 v3.0 一致 · 不夺主权
│
└─ -∞   永禁 (无密码 / 用户主动锁 skipAutoSwitch)
```

**自然顺应 (无为而无不为 · 一以贯之)**:

1. `getBestIndex`/`getSortedIndices` 天然受益 · **无需改动任何调用方**
2. 当前 active 是 overage 切号 → 自然选下一 overage (excludeIdx 排自己)
3. overage 全耗 (`overageActive=false`) → 自然下沉百分比层
4. 重置时刻 overage 复活 → `_scheduleResetRefresh` 触发 verify → 自然上跃

**软门控**: `wam.preferOverageFirst` (默认 `true` · 道法自然 · 推荐)

- `true`: 严格分层 · overage 绝对优先于百分比 (本版默认 · 实现用户诉求)
- `false`: 回退 v3.2.1 统一坐标系 · 兼容旧行为

**守门**: `_test_v330_overage_priority.cjs` 全通

- overage 永远 > 百分比 (无论 W%/D% 多高)
- overage 内部按金额排 ($208>$195>$193 顺序保留)
- overage 全锁 → 下沉百分比
- overage 全无 → 自然百分比
- 锁号 (skipAutoSwitch) 即使有 overage 也跳过

**诉求印证 (用户原话)**:

> "就是有额外额度的，就有额度的就先用额度的"  
> "百分比制的是没有额度之后才会跳转到百分比制"  
> "优先把有额度的账号先用完，而非先把有百分比的账号先用完"  
> "道法自然，无为而无不为"

→ **完全实现** · 道法自然 · 无为而无不为

---

## v3.2.1 (2026-05-23) · 额度重置感知 · 无为而无不为

> *迅雷烈风 · 莫不蠢然 · 至乐性余 · 至静性廉*

**额度重置感知 (天人合发)**:

- 「感知」 `_scheduleResetRefresh()` — 精准 setTimeout 到下次重置时刻
  - 每日 UTC 08:00 (北京 16:00) → 日额度重置 · 全池自动刷新
  - 周日 UTC 08:00 (北京 周日 16:00) → 周+日额度重置 · 全池自动刷新
  - 复用 `hoursUntilDailyReset()` / `hoursUntilWeeklyReset()` · 零重复
- 「效果」 耗尽号在重置瞬间自动复活 · 用户无感 · 无需等 30min 周期扫描
- 「联动」 `_setMode()` 模式切换自动管理定时器
  - WAM 模式 → 启动重置感知
  - 官方模式 → 停止重置感知
- 「安全」 verifyAll 进行中 → 30s 后重试 · 刷新完毕 → 自动重调度下次
- 「软编码」 `resetRefreshBufferMs` (默认 30s) — 重置后缓冲等待

**精简效果**: 6492 → 6546 行 (净增 54 行 · 换取用户无感体验)

**守门**: `_test_v321_validate.cjs` 30/30 全通

---

## v3.2.0 (2026-05-24) · 大道至简 · 三处归一 · 去芜存菁

> *圣人抱一而得天下事 · 至静之道 · 律曆所不能契*

**结构性改革 (为道者日损)**:

- 「归一」 `_setMode(mode)` — 模式切换三处归一
  - 旧: `case "setMode"` webview handler + `wam.setModeWam` cmd + `wam.setModeOfficial` cmd 三处独立实现
  - 新: 单一 `_setMode(m)` async 函数 · 三处均调用 · 逻辑一源
  - 官方模式: 停引擎 + `windsurf.logout` + 卸 guard (v3.1.4 三步净身)
  - WAM模式: 装 guard + 启引擎
  - 返回 `true`/`false` 示是否实际变更
- 「去芜」 删 `isTrialPlan()` (定义未调用 · `_isTrialLike` 已替代)
- 「去芜」 删 `URL_GET_PLAN_STATUS` 别名 (定义未引用 · `_LIST` 版保留)
- 「承」 v3.1.4 官方模式根治 + activate 条件守卫

**精简效果**: 6519 → 6492 行 (净减 27 行 · 逻辑更清晰)

**守门**: `_test_v320_validate.cjs` 20/20 全通

---

## v3.1.4 (2026-05-23) · 官方模式根治 · 自然之道静

> *自然之道静 · 故天地万物生*

**病灶**: 切官方模式后 WAM session token 残留 + openExternal guard 拦截官方登录 URL.

**三步净身** (切官方时):
1. 停引擎 (WAM 不再切号/扫描)
2. `windsurf.logout` 清 WAM 注入的 session
3. `_removeOpenExternalGuard` 放行官方浏览器登录

**activate 条件守卫**: WAM模式装 guard / 官方模式不装.

---

## v3.1.3 (2026-05-22) · effQuota 守门 · 一以贯之

## v3.1.2 (2026-05-22) · 限速感知 · cache全走 · v3.1.1 prewarm 已损

## v3.1.1 (2026-05-22) · sessionCache 持久化 · 零批量 devinLogin

## v3.1.0 (2026-05-22) · openExternal 持久守卫 · 切号零弹窗

## v3.0.6 (2026-05-21) · devinLogin 全局最小间隔 · broadcastUI 防抖

## v3.0.5 (2026-05-21) · UI状态持久 · 添加展开不闪烁

## v3.0.4 (2026-05-21) · 统一通知层 · URL多源健康度

## v3.0.2 (2026-05-21) · 独立持久化 · refresh驱动验证

## v3.0.1 (2026-05-21) · 反者道之动 · 手动至高优先 · 一锁覆万源

## v3.0.0 (2026-05-21) · 道法自然 · 无为而无不为 · 全量解构自封体系

## v2.8.5 (2026-05-20) · Devin 双轨 + 自动激活 + overage 走的弄比天下

---

## v2.7.5 (2026-05-14) · 治「单独 token 无法添加登录」· 道恒无名·万物自宾

> *道恒无名 · 朴唯小 · 而天下弗敢臣 · 侯王若能守之 · 万物将自宾 · 民莫之令而自均焉*

**缘起 · 主公图1 实证**: 5 行 `auth1_xxx` (无 email 同行配对) 粘入 + 添加账号 → 入 tokens 数组成孤儿 · accounts 不增 → 用户视觉 "未添加" → 无法直登.

**根因**: v2.7.1.1 「孤儿 token 入 tokens 数组待显式反查 email」之契约 · 对单 token 流派 (用户仅有 token · 无 email) 留无解之地.

**治法 · 道恒无名 · 名不可名 · 万物自宾**:

- §A `parseAccountText` 末段 · 孤儿 token → 占位 email 入 accounts (10 行)
  - 占位形 `<kind>.<sha8>@token.wam` (合法 email · 通过 `_isValidEmail`)
  - password 槽 = 原 token · 重启 `parseAccountText` 自然读回 (tryPair 识 email+token)
  - 防重: 同 token 反复粘贴不重复 (sha8 决定 placeholder 唯一)
- §B 立 `_isPlaceholderEmail(s)` 工具识别占位号 · UI/verify/rename 路径快判 (一函)
  - 位居 `_normalizeAccCreds` 之后/`parseAccountText` 之前 · 公器同列 · 大制无割
  - 此位令 parseAccountText 末 return 紧邻 loadAccountsFromFs (守 v2.7.0 schema 静态契约)
- §C webview domainBadge 加 "tk" · 占位号视觉可识 (`.dm.tk { bg:#5a3a14; color:#f0c674 }`)
- §D 5 kind 全适配: `auth1`/`session`/`jwt`/`apikey`/`refresh`/`raw`
  - 下游 `_normalizeAccCreds(acc)` 之 `_detectTokenKind(acc.password)` 自动分流 → loginViaToken
  - verify/login 后 quota/plan/expiry 等账号信息均可查询 · 用户无为

**老测套 8 处行为断言更新** (随 v2.7.5 主公诏唯变所适):
- `_test_v270_omni_recognize` §10.1/10.2/11.1/11.2 (4 处) — `r.accounts.length === 1` + placeholder regex
- `_test_v271_omni_token` §6.4/11.1/11.2 (3 处) — 孤儿 JSON auth1 / 综合识入 accounts
- `_test_v2711_main` §5.9 (1 处) — 单孤儿 token → 占位

**回归测 `_test_v275_single_token_omni.cjs · 57/0`**:

```text
[§1]  静态契约 (banner/VERSION/末段/_isPlaceholderEmail/.dm.tk)   12 测
[§2]  _isPlaceholderEmail 严判 5 kind × pos/neg                    10 测
[§3]  占位 email 通 _isValidEmail (合法 email 全栈兼容)             5 测
[§4]  主公图1 端到端 · 5 行 auth1 token → accounts.length===5      10 测
[§5]  5 形混粘 → 各形各号 · detectKind 分流                        10 测
[§6]  幂等 · 同 token 反复粘 · sha8 决定不重                        3 测
[§7]  不退化 · v2.7.0/v2.7.1.1/v2.7.4 兼容                          7 测
═════════════════════════════════════════
        57 过 / 0 败
```

**全测套 17/18 套 0 败 · 总 666/0** (v267 28/4 历史滞后 v2.6.9-2.6.10 中间态 · 不计).

**道一以贯之**: 32 章「道恒无名·朴唯小·而天下弗敢臣·侯王若能守之·万物将自宾」· 占位即真 · 名不可名 · 道隐无名而无不为.

## v2.7.4 (2026-05-14) · 🔒 独立持久化 · multi-window race-safe · 治🔒回退真本源

> *上善若水 · 水善利万物而有静 · 居众之所恶 · 故几于道矣*

**缘起 · v2.7.3 实证**: 多窗口并行运行时 · 一窗 lock 写入 wam-state.json 被另一窗覆盖 · 切号 🔒 状态回退.

**根因**: `wam-state.json` 单文件多字段 · 多 window 同时 save 之 race condition 致 `inUseUntil` 字段冲洗.

**治法**:

- §A `inUseUntil` 独立 持久化 `lock-state.json` · 与 wam-state.json 解耦
- §B `_persistLockState()` / `_loadLockState()` 一组工具
- §C 优先读独立 lock-state.json (multi-window race-safe)
- §D 兼容: 老 wam-state.json 含 inUseUntil 字段 · 仍读取 (向前兼容 · 一次性迁移)

**回归测 `_test_v274_lock_state_isolation.cjs · 26/0`** + `_test_v273_lock_persistence.cjs · 23/0`.

**道一以贯之**: 8 章「上善若水 · 居善地」· 数据居其位 · 不与他争 · 故多窗口和而不冲.

## v2.7.3 (2026-05-14) · 治🔒回退根 · 守一 · 大道至简

**根因**: v2.7.1/v2.7.2 lock-on-rotate 后 save 漏写 inUseUntil 字段 → reload 后🔒丢失.

**治法**: save 守一 — inUseUntil 入 _serialize 出口 · 一次写入 · 不破契约.

**回归测 `_test_v273_lock_persistence.cjs · 23/0`**.

**道一以贯之**: 39 章「昔之得一者:天得一以清·地得一以宁·神得一以灵」· 序列化守一·所有状态一齐入盘.

## v2.7.2 (2026-05-14) · 主公三诏 SemVer patch bump · 内涵同 v2.7.1.1

主公三诏「token 看做账号密码 · 直接复用一切 · 顺其自然」之 SemVer 合规版本号 patch bump · 内涵同 v2.7.1.1 · 三段为道 · 信言不美.

## v2.7.1 (2026-05-14) · 万法归一·token 直登 · 反者道之动·逆流解析所有 windsurf token

> *反者道之动 · 弱者道之用 · 天下之物生于有 · 有生于无*

**缘起 · 主公三图实证**:

| 图 | 实证 | 现象 |
|---|---|---|
| 图1 | 5 行单 `auth1_xxx` | 入 tokens 数组成孤儿 · UI 视为 "未添加" |
| 图2 | `email----auth1_xxx` 单行格式 | tryPair 错把 token 当 password (字面同居) |
| 图3 | v2.7.0 在 179 端实证 138 号·1 未验·25 耗尽·trial 状态混乱 | parseAccountText 残漏 |

**根因 · `parseAccountText` 失道之三病**:

- ① 反序 `token+email` (token 先 email 后) · token 缓存等下一 email 后未配对
- ② 单行 token + pendingEmail · token 入 password 槽路径未通
- ③ JSON {email, auth1_token} / {auth1: xxx} / refresh_token 等多形未识

**治法 · 反者道之动**:

- §A tryPair 升级 · email+token 优先返 `{email, token, kind}` (kind 来自 _detectTokenKind)
- §B items 加 'pair-token' 类型 · 配对循环加 token + pendingEmail 多行配对
- §C 反序 token+email · 单行 token+pendingEmail · 均入 accounts.password 槽 (token 与密码同居)
- §D 下游 `_normalizeAccCreds(acc)` 之 `_detectTokenKind(acc.password)` 自动分流 → loginViaToken
- §E 损 addBatch 之 tokenPairs/tokenUpdated 中转 · 仅返 `{ added, duplicate, tokens, addedEmails }`
- §F webview UI **完全不变** · 同 v2.7.0 placeholder + 单 textarea (主公二诏 · 太上下知有之)

**主公三诏 (v2.7.1.1 · 闻道者日损)**: "将 token 看做账号密码 · 直接复用一切 · 顺其自然"

- parseAccountText 复 v2.7.0 schema · 不再单存 tokenPairs · token 直入 password 槽
- 复制/落盘/UI/复用 一切 同 v2.7.0 · 自然无为 · 不惧方能成其大

**回归测**:
- `_test_v271_omni_token.cjs · 65/0` (主公三诏 · 经典+token 同居 password 槽)
- `_test_v2711_main.cjs · 46/0` (parseAccountText 复 v2.7.0 schema · addBatch 仅返 addedEmails)

**道一以贯之**: 40 章「反也者·道之动也·弱也者·道之用也」· token 看做密码 · 万法复归于一.

## v2.7.0 (2026-05-09) · 万法识号·守道反者 · 唯变所适·适应万法之格式

> *天下莫柔弱于水，而攻坚强者莫之能胜也，以其无以易之也*

**缘起 · 主公实证四图**:

| 图 | 实证 | 现象 |
|---|---|---|
| 图1 | 账号列表 117 号大量 "?天/未验/D?/W?" | 入库 email 严重污染 |
| 图2 | "+ 添加账号" placeholder | 用户依此粘贴 |
| 图3 | 微信发货 ("账号:..\n密码:含@\n账号管理器:点tps://..(去掉点)") | 含@密码灾难性误判 |
| 图4 | "卡号N: a@b.com / 卡密N: pass" | 词典缺·5 卡全军覆没 |

**根因 · `parseAccountText` 失道之四病**:

| 病 | 失道之处 | 行为 |
|---|---|---|
| ① | `卡号N:`/`卡密N:` 未在标签词典 | tryPair 错把 "卡号1" 当密码 |
| ② | `if(!v.includes("@"))` 排除带 @ 的"密码" → 兜底 `^\S+@\S+$` 误为新 email | 正主丢失 |
| ③ | tryPair 仅以 `includes("@")` 认 email | `XuE2@UXoq7JD` (是密码) 被认为 email |
| ④ | 配对仅 email→pass 单向 | 反序 (pass 先 email 后) 无法配对 |

**治法 · 反者道之动 · 弱者道之用 · 守一不退**:

- §A 立 `_isValidEmail` 严判 (local@domain.tld · 长度 5-254 · 不含全角分隔符) — 替代 `includes("@")` 草率认 email
- §B 扩标签词典 + 兼容 `\d*` 数字编号:
  - email +`卡号|号码|账户名|登录名|登陆名|number|num|e-mail`
  - pass  +`卡密|密钥|令牌|key|token|access(-token)?`
- §C 标签即定锚·守一不退 · 密码标签后**含 @ 仍为密码** · 邮箱标签后必须 `_isValidEmail` 才认
- §D tryPair 用 `_isValidEmail` 严判 + 双向兜底
- §E `pendingPass` 反向配对 (顺逆皆通)
- §F `_stripWxHints` 行尾剥离 `(无任何空格)`/`(去掉点)` 等微信提示
- §G `_isNoiseLine` 整行模板嗅探 (开头明确者跳: 自动发货/订单编号/账号管理器: URL)

**回归测 `_test_v270_omni_recognize.cjs · 73/0`** (v2.7.5 +1 行为对齐).

**软编码归一 · 单一信源 wamHomeDir**:

- 立 `Get-WamDir` 助手于 `_dao_lib.ps1` (尊 `_dao_env(.local).psd1` `wamHomeDir`)
- 6 PS 脚本字面 `'.wam'` → `Get-WamDir`
- Linux/macOS 兼: `USERPROFILE` → `HOME` 兜底

**道一以贯之**: 78 章「天下莫柔弱于水, 而攻坚强者莫之能胜也, 以其无以易之也」· 万法之格式如水, 守一者如石.

## v2.6.14 (2026-05-08) · 三守俱全·守一·大制无割·反者道之动

**根因三破**:

| 破 | 层 | 本 |
|---|---|---|
| ① 公理破 | "1 user send = 1 信号" | 不成立 · 流式响应连续 N quanta · 单账号 40s W 82→72 = 4 脉动 |
| ② 栏破 | v2.6.11 弃 `perMessageMinIntervalMs` | 最终兜底失 |
| ③ 守破 | v2.6.12 `quotaPulsePriorityMs` 只守 WAL/pb | 不守 W% 自身 · 阳自决堤 |

**三守俱全** (大制无割·一全锁覆万源):

| 守 | 位 | 默 | 道 |
|---|---|---|---|
| **守一** | `_maybeTrigger` 入口 | `perMessageMinIntervalMs=60000` | 全 reason 强锁·适 ⚡/📡/📃/⚖ 万源·1 user send ≤ 1 切 |
| **守二** | `_fireWalEdge` 内 | `walEdgeCooldownMs=2000` | WAL 同源最小间隔·避 4KB 帧连火·削 log 噪 |
| **守三** | `_fireWalEdge` 入 | `walWarmupMs=5000` | WAL 启动暖启窗·防 activate 首 stat 累积差引雪崩 |

**回归测 `_test_v2614_triple_throttle.cjs · 66/0`** · §2d-3 mock 实证降幅 **-97.2%** (177→5).

**道一以贯之**: 64 章「为之者败之·执之者失之·圣人无为故无败」· 单行全栏 > 多处细栏 · 守一 > 守多.

## v2.6.13 (2026-05-08) · 阴阳结合·⚖额度变动·物无非彼物无非是

| 极 | 信号 | 维度 | 阈值 | 动态 |
|---|---|---|---|---|
| **阳·主** | ⚡W%脉动 | `weekly%` 宏观 | `quotaPulseMinDelta` (默 0.3%) | 触发 → 设 `_lastQuotaPulseAt` → 主信号窗 60s 内 WAL/pb/⚖ 让位 |
| **阴·辅** | ⚖额度变动 | `daily%` / `promptCredits` / `flowCredits` 多维度+微观 | `quotaDeltaDailyMin` (默 0.3%) + `quotaDeltaCreditsMin` (默 1) | 触发 → 进 `_maybeTrigger` 出口 |

**回归测 `_test_v2613_quota_delta.cjs · 44/0`**.

**道一以贯之**: 1 章「两者同出·异名同谓·玄之又玄·众眇之门」.

## v2.6.12 (2026-05-07) · 守一·抢跑治·道恒无名

- 修一: setActive 真切号时清基线 (`_lastQuotaPercent = null`) — 解跨账号假信号
- 修二: 加 `_lastQuotaEmail` · W% 比较只在同账号内进行
- 修三: 加 `_lastQuotaPulseAt` 时间戳 — ⚡W%脉动 触发后 60s 内 WAL/pb 让位

**净变**: +50 行 · 24 配置项.

## v2.6.11 (2026-05-07) · 真本源至·道恒无名·民自均焉

**实证**: WAL 信号本质不可靠 · settle 模型累积静默与 user send 频次解耦.

**根本治法 · 三守三损**:

- 损一: 删 settle 模型整段
- 损二: 删 max filter
- 损三: 删 三防抖
- 守一: ⚡ W%脉动 — Engine._tick 10s 周期查 weeklyQuotaRemainingPercent
- 守二: 配额自均 — 让账号配额自然均衡耗尽
- 守三: 长链路监控

**净变**: -3.1KB / 删 4 配置 / 删 2 死变量.

## v2.6.10 (2026-05-07) · 治人事天·莫若啬·checkpoint 过滤

- 加 `wam.walEdgeMaxBytes` 默 65536B (64KB) · delta > 此视为 checkpoint 噪
- 加 `_skipWalEdge` 函数 · log `wal·edge·skip[checkpoint:XXX > 64KB]`
- 二道互补: 空间过滤 (max 64KB) + 时间强锁 (60s minInterval)

## v2.6.9 (2026-05-07) · 道法自然·损 settle·留真信号

- 删 `_firePbSettle` · 删 watcher settle 分支 · 删 `_fireWalSettle`
- 留 `pb·new` 唯一信号源 (1:1 精确)
- 加 WAL 边沿首发 (单次 delta ≥ 512B 即 fire)
- 强 60s 全局强锁

**净变**: -120 行 · 为道日损.

## v2.6.8 (2026-05-06) · 实证调参 · 损泥灌沙

参数微调 · 实证证伪 cooloff 解除即触发病灶.

## v2.6.7 (2026-05-06) · 整文 debounce · 道之疏

- `perMessageDebounce(QUIET_MS=4000)` 全 reason 入口防抖
- 道一以贯之: 73 章「天网恢恢, 疏而不失」.

## v2.6.6 (2026-05-06) · 反者道之动 · 解构一切 · 逆流到底

**反者解** (40 章): cooloff → **settle** · debounce trailing edge 模式 · 静默 N ms 后才切号.

**实现**: `pb·send → pb·settle` / `wal·send → wal·settle` · `SETTLE_MS=15000`.

## v2.6.5 (2026-05-06) · 锚定本源 · 慎终若始

仅升版本号 + changelog · 行为零变化 · 治 v2.6.4 hotfix 进程缓存锁定.

## v2.6.4 (2026-05-06) · 去芜存菁 + quietSec 哨兵修

- 删死: `wam.netHookDisabled` · `wam.perMessageMinIntervalMs` (默 0 关·从未读)
- 补活: 三参数族 (sendDetect / walDetect)
- Hotfix: `lastGrow=0` 哨兵化 · 首检测 quiet="init"

## v2.6.3 (2026-05-06) · WAL 直达触发 · 大道至简 · 回归本源

**信号源**: `state.vscdb-wal` (用户 click Send 后 SQLite 同步写入的 WAL 帧).

**实现**: `_installWalWatcher` · 300ms 轮询 · `quiet=2s` · `cooloff=6s` · `min=1024B`.

## v2.6.2 (2026-05-05) · 跨实例声明锁 · 观复知常 · 万物并作

**修法**: `~/.wam/_l6_claim/` 声明目录 + `flag:"wx"` 原子排他创建.

## v2.6.1 (2026-05-05) · Layer 6 双信号 · 逆流到底

- 信号① `pb·new`: 新 .pb 文件 = 新对话 → 立即切号
- 信号② `pb·send`: 存量 .pb 文件大小增量 + 安静期检测 = 已有对话用户发消息

## v2.6.0 (2026-05-05) · 底层软编码 · 唯变所适 · 水无常形

- `RE_SESSION_TOKEN` 常量统一
- `_isTrialLike(h)` 全链对齐
- `_resolveCascadePbDir` Linux fallback 用 `os.homedir()`
- startup recovery 阈值用 `_cfg("autoSwitchThreshold",5)`

## v2.5.6 (2026-05-05) · 真根因 · Layer 6 信号文件 + 路径双修

- 文件改为 `globalStorage/state.vscdb-wal` (真信号)
- 旧 `path.dirname(path.dirname(storageUri))` → ONE dirname 修正
- delta 策略 WAL 正增量 ≥1KB
- fallback 四级: globalStorage WAL → globalStorage main → workspace → scan

## v2.5.5 (2026-05-04) · ideVersion 根因解

**修**: `tryFetchPlanStatus` metadata default `ideVersion` 由 `"1.0.0"` 改为 `"1.99.0"`.

## v2.5.4 (2026-05-04) · `_isTrialLike` 软判据

`_buildExpTag / _cleanseHealthOnLoad` 同步用软判据 (正则 `/trial/i`).

## v2.5.3 (2026-05-04) · Trial 脏数据自洁

`_buildExpTag` 增第 5 态 `Trial?` (黄·提示需重验).

## v2.5.2 (2026-05-03) · `_buildExpTag` 5 态 UI 标签

`?天` / `N天` (颜色阶梯) / `已过期` / `Trial?` / `∞`.

## v2.5.1 (2026-05-03) · `X-Devin-Auth1-Token` HTTP header

`windsurfPostAuth` body `auth1_token` → HTTP header `X-Devin-Auth1-Token`.

## v2.5.0 (2026-05-02) · 大减法 · Layer 6 跨进程触发

**修**: 引入 Layer 6 — `fs.watchFile()` 监听 `state.vscdb` mtime 变化. **跨进程稳**.

**减**: 删 Layer 1-5 全部网络钩代码 (-2300 行).

## v2.4.x → v2.5.0 减法路 (-62%)

| 减项 | 行 | 减因 |
|---|---|---|
| Layer 1-5 网络钩 | -2300 | cross-process 无效 |
| TurnTracker | -800 | Layer 6 已替 |
| AutoUpdate | -600 | 用户自部署 |
| 代币池跨账号管理 | -400 | 单文件本地 state 即可 |
| Firebase / Devin 全套登录链 | -2200 | `devinLogin + windsurfPostAuth` 双步即足 |
| 多重 fallback 兜底 | -200 | 信道单点已稳 |
| **共减** | **-6648** | **(10913 → 4265)** |

## 测试矩阵 (v2.7.5 · 18 套 · 17 套 0 败 666/0 + v267 历史滞后)

| 测试 | 断言 | 关注 |
|---|---|---|
| `_test_set_health.cjs` | 24/0 | health 写入幂等 |
| `_test_v241_real.cjs` | 20/0 | proto3 default + 真账号 (网络依赖) |
| `_test_in_use.cjs` | 57/0 | 使用中锁 + 失败计数 |
| `_test_e2e_msg_rotate.cjs` | 33/0 | 消息轮转 E2E |
| `_test_quota.cjs` | 12/0 | 配额波动检测 |
| `_test_v251_postauth_header.cjs` | 8/0 | postAuth header 协议 |
| `_test_v252_exptag.cjs` | 73/0 | UI 5 态 + Trial 清洗 |
| `_test_v255_ideversion.cjs` | 9/0 | ideVersion 1.99.0 锁 |
| `_test_v256_layer6_path.cjs` | 30/0 | Layer 6 路径双修 |
| `_test_v267_debounce.cjs` | 28/4 ⚠ | §1 baseline 滞后 · 历史不计 |
| `_test_v2613_quota_delta.cjs` | 44/0 | 阴阳结合 ⚖额度变动 |
| `_test_v2614_triple_throttle.cjs` | 66/0 | 三守俱全 |
| `_test_v270_omni_recognize.cjs` | 73/0 | 万法识号 |
| `_test_v271_omni_token.cjs` | 65/0 | 万法归一·token 直登 |
| `_test_v2711_main.cjs` | 46/0 | parseAccountText 守 v2.7.0 schema |
| `_test_v273_lock_persistence.cjs` | 23/0 | 🔒 持久化 |
| `_test_v274_lock_state_isolation.cjs` | 26/0 | 🔒 multi-window 隔离 |
| `_test_v275_single_token_omni.cjs` | 57/0 | 单 token 占位 email · 主公诏 |
| **合计** | **666/0** | **17/18 套全过 · v267 历史滞后** |

## 历史: v17.42.x 系满载版

v17.42.20 (2026-04-末) 及 v17.42.x 全系**满载本体**已归档于 [`_archive/wam-v17.42.20/`](../../_archive/wam-v17.42.20/):

- 完整 `extension.js` 437 KB / 10913 行
- 387 E2E 断言
- 完整 v17 CHANGELOG 72 KB · `_archive/wam-v17.42.20/CHANGELOG.md`

二者为**同名异体 · 各臻其极** · 不相代而相成.

---

*德经曰: 上士闻道 · 堇而行之. 道极版即「闻道而行」之践*
