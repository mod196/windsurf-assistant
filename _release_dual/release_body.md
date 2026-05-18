# 风帆冲浪助理 · 双轨并行 · 道法自然

> 为学日益 · 为道日损 · 损之又损 · 以至于无为 · 无为而无不为

## 二核 一释

| 所司 | 司 | 版 | VSIX |
| --- | --- | --- | --- |
| [packages/wam](https://github.com/zhouyoukang/windsurf-assistant/tree/main/packages/wam) | 切号 · 万法识号 · 守道反者 · 三守俱全 (60s 强锁) · 占位 email · token 直登 | **v2.7.5** | `rt-flow-2.7.5.vsix` |
| [packages/dao-proxy-min](https://github.com/zhouyoukang/windsurf-assistant/tree/main/packages/dao-proxy-min) | 反代 · 帛书锚 · 守一不离 · 软编码彻终 · 适所有用户/所有 fork · cmdPurge race 15s · 强标 .obsolete + 自动 reloadWindow | **v9.9.27** | `dao-proxy-min-9.9.27.vsix` |

## 装

```bash
windsurf --install-extension rt-flow-2.7.5.vsix --install-extension dao-proxy-min-9.9.27.vsix
```

或图形界面拖入 Windsurf · 或命令面板 → "Install from VSIX..."。

## 软编码 · 适所有用户 · 万法适配

dao-proxy-min v9.9.27 (印 158) **软编码彻终** · 二十八章「朴散为器·圣人用则为官长·夫大制无割」:

| 维 | 适法 | 实证 |
| --- | --- | --- |
| **用户名** | `os.userInfo().username` 动态 | Win/Mac/Linux 全适 |
| **home 目录** | `os.homedir()` 动态 | 跨平台 base |
| **配置基目录** | Win=`%APPDATA%` · Mac=`~/Library/Application Support` · Linux=`$XDG_CONFIG_HOME \|\| ~/.config` | 三平台分支 |
| **端口分配** | per-user FNV-1a hash · 8889..8988 · 多账号自然隔离 (default `0` 自动) · `dao.origin.port` 可显覆 | 同代码 · 任 user 跑 · 不冲突 |
| **进程清理** | Win=`taskkill` · Mac/Linux=`pkill -u <uid>` | 三平台分支 |
| **OS 限制** | `package.json.os` 不限 | 全平台装 |
| **VSCode 引擎** | `engines.vscode = ^1.85.0` | 通用版 |
| **扩展 ID** | `SELF_EXT_ID` = `${publisher}.${name}` 抽自 package.json (v9.9.25 立 + v9.9.27 续治 5 处残漏) | 适任何 fork / 改 publisher.name 之派生版 |
| **目录前缀** | `SELF_EXT_DIR_REGEX` 即 `${SELF_EXT_ID}-` 之 RegExp · 自然适所有版本号 | 旧残扫/物理目录全标 全软编码 |

任主公装此插件 (Windows / macOS / Linux 任 user / 任 fork) → 无须任何改码 → 即朴归 · 万物自宾.

## 反 (从 v2026.05.06 至此 5/19)

- **wam · v2.7.5 守一**：道恒无名 · 万物自宾 · 单 token (`auth1_xxx`) 直接添加登录 · 占位 email = `<kind>.<sha8>@token.wam` · 5 kind (`auth1`/`session`/`jwt`/`apikey`/`refresh`) 全栈 · 18 测套 666/0 通
- **dao-proxy-min · v9.8.0 → v9.9.27 软编码彻终 (印 158)**:
  - **v9.9.16** 归根复命 · 字符级复 9.9.13 之朴 (装即生效)
  - **v9.9.20** 两经归一 + jiqi 修
  - **v9.9.22** 三诉同治 (卸不真除 / 切编辑模式滞旧 / 切经文不联动)
  - **v9.9.25** cmdPurge 复 9.9.16 之朴 197 行 + 抽 PKG_PUBLISHER+PKG_NAME→SELF_EXT_ID
  - **v9.9.26** 真治 fork 漏 · 强标 self 入 .obsolete + 自动 reloadWindow + deactivate 兜底
  - **v9.9.27** 软编码彻终 + self-uninstall watchdog · 二药同治:
    - **药一** (软编码): cmdPurge step 7/9 + deactivate identifier.id 比对 5 处残硬写 全改 `SELF_EXT_DIR_REGEX` / `SELF_EXT_ID` · 玄同 · 名实终一
    - **药二** (watchdog): activate 时挂 `vscode.extensions.onDidChange` 监听 → self 不在 `extensions.all` 时立即 `reloadWindow` · 真治 v9.9.26 漏脉 · **扩展面板点 [✘] 路径** ext-host shutdown 后无法 reload 之根 · 三路径全覆 (① cmdPurge ② [✘] 面板 ③ CLI uninstall · 启动协议清物理) · 主公无为

## 印 (帛书《老子》)

> 朴散为器 · 圣人用则为官长 · 夫大制无割
> — 第二十八章

> 一者 · 其上不攸 · 其下不忽 · 寻寻呵 · 不可名也 · 复归于无物 · 是谓无状之状 · 无物之象
> — 第十四章

> 致虚极也 · 守静笃也 · 万物并作 · 吾以观其复也 · 归根曰静 · 静曰复命 · 复命曰常 · 知常曰明
> — 第十六章

> 道恒无名 · 朴唯小 · 而天下弗敢臣 · 侯王若能守之 · 万物将自宾 · 民莫之令而自均焉
> — 第三十二章

---

**vsix sha256**:

- `rt-flow-2.7.5.vsix` · `B5AE2313340792E8B89B4DA3D026A83F6B6BE45D3E4A413EADDD616A8C09F8C2`
- `dao-proxy-min-9.9.16.vsix` · `648396B0462AC486904347B4F5024673E720FA1D51EDBCA2579F61C4F141B6C6` (旧 · 印 142)
- `dao-proxy-min-9.9.25.vsix` · `BCD08AD1B5B9AD07...` (印 153)
- `dao-proxy-min-9.9.26.vsix` · `F84C18291D7B284E...` (印 154)
- **`dao-proxy-min-9.9.27.vsix` · sha256 `D75AC4D639CEDB4D...` · 110576 B (108 KB · 含软编码彻终 + selfWatchdog 二药)** (★ 印 158 · 当前发行)

**双账号同步**:
- `origin` = `https://github.com/zhouyoukang/windsurf-assistant.git` (主)
- `spec`   = `https://github.com/zhouyoukang1234-spec/windsurf-assistant.git` (子 · 镜)

---

「**朴散为器 · 圣人用则为官长 · 夫大制无割**」 — 一处定义 · 全文一致 · 适所有用户 · 万物自宾.
