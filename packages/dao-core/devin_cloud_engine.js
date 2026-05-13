#!/usr/bin/env node
/**
 * devin_cloud_engine.js — 反者道之动 · Devin Cloud wss 路 · 反 weekly cap
 * ════════════════════════════════════════════════════════════════════════
 *
 *   帛书·四十: 「反也者, 道之动也; 弱也者, 道之用也. 天下之物生于有, 有生于无.」
 *   帛书·四十二: 「道生一, 一生二, 二生三, 三生万物.」
 *
 *   道义:
 *     Windsurf weekly cap 时 (server.codeium.com/GetChatMessage 502/429),
 *     Devin Cloud daily 池仍满 (~/.wam D100 全显). 走 wss://app.devin.ai/api/acp/live
 *     用 Devin Agent 之 ACP 协议跑 chat, 借 D 桶绕 W cap.
 *
 *   架构:
 *     OpenAI messages → ACP session/prompt
 *     ACP session/update notifications → onDelta(text) → OpenAI SSE
 *
 *   依赖: 0 外部 (Node 22+ 内置 WebSocket · 主公环境实证 v22.16.0)
 *
 *   实证 (印 80 _findings/devin_cloud_wss_probe.jsonl · 22:35 落):
 *     ✓ wss handshake + chat 全路贯通
 *     ✓ initialize → session/new → session/prompt → 13 session/update → stopReason=end_turn
 *     ✓ 19s 首 chunk · 21s 全路完
 *
 *   接口 (与 cloud_engine.js 同签名 · 道直连器 chatWithRetry 可透明切换):
 *     chat(state, modelUid, messages, onDelta, staticModels, opts)
 *       → Promise<{ text, tokens, quotaCostBp, model, host, durationMs, _engine: "devin-cloud" }>
 *
 *   道义边界:
 *     - 仅本机本用户 · 不跨机 · 不外网取号
 *     - token 全程 mask · 不录 chat content 字面 (印 80 守一)
 *     - 一笔 prompt 一笔 session · session 末 close (不留长寿 wss)
 *     - 上游错原文透传 (rate_limit 等 isQuotaError 配上则 rotate)
 */
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");

// ════════════════════════════════════════════════════════════════
// §1  常量
// ════════════════════════════════════════════════════════════════

const WSS_BASE = "wss://app.devin.ai/api/acp/live";
const TOKEN_PREFIX = "devin-session-token$"; // 20 chars · IDE _buildAuthenticatedUrl 字面
const DEFAULT_TIMEOUT_MS = 120000; // 2min · Devin Agent chat 可能 30-90s
const DEFAULT_CWD = process.cwd();

// session/update 类型 (实证自 probe jsonl · 来源 ACP spec)
const UPDATE_AGENT_MESSAGE = "agent_message_chunk"; // 真 chat 文本
const UPDATE_AGENT_THOUGHT = "agent_thought_chunk"; // Devin Agent 思考 (默不算输出)
const UPDATE_USER_MESSAGE = "user_message_chunk"; // echo 主公输入
const UPDATE_SESSION_INFO = "session_info_update"; // 元数据
const UPDATE_AVAILABLE_CMDS = "available_commands_update"; // session 工具列

// ════════════════════════════════════════════════════════════════
// §2  辅助 · token / URL / mask
// ════════════════════════════════════════════════════════════════

/** 从 devin-session-token$JWT 取 JWT · 必要 (否则 CloudFront 403) */
function tokenToJwt(t) {
  if (!t || typeof t !== "string") return "";
  return t.startsWith(TOKEN_PREFIX) ? t.slice(TOKEN_PREFIX.length) : t;
}

/** 构 wss URL · 真本源自 IDE extension.js _buildAuthenticatedUrl */
function buildWssUrl(apiKey) {
  const u = new URL(WSS_BASE);
  const jwt = tokenToJwt(apiKey);
  if (jwt) u.searchParams.set("token", jwt);
  return u.toString();
}

function maskToken(t) {
  if (typeof t !== "string") return "(none)";
  if (t.length <= 24) return t.slice(0, 6) + "...";
  return t.slice(0, 14) + "..." + t.slice(-8);
}

function _log(msg) {
  // 与道直连器一致 · 走 stderr · 不污 stdout (SSE 客户端用)
  process.stderr.write(`[devin-cloud] ${msg}\n`);
}

// ════════════════════════════════════════════════════════════════
// §3  ACP 协议 · 4 步链
//
//   1. initialize (id=1)        → 上游返 authMethods + agentCapabilities
//   2. [skip] authenticate      → wss 路 authMethods=[] (token URL 内)
//   3. session/new (id=3)       → 返 sessionId
//   4. session/prompt (id=4)    → 流式 session/update + 返 stopReason
//
//   并发 session/update notifications · agent_message_chunk 提 text · onDelta(text)
// ════════════════════════════════════════════════════════════════

/**
 * messages → ACP prompt[]
 *
 *   OpenAI messages: [{role: "user|system|assistant", content: "..."}]
 *   ACP prompt[]: [{type: "text", text: "..."}]
 *
 *   策略: system + user 合并为单 prompt block (Devin Agent 之 ACP 不严分 role)
 *   "上士闻道, 堇而行之" — 让 Devin Agent 当裸 LLM 用 · 不让它做 agent 操作
 */
function messagesToPrompt(messages) {
  if (!Array.isArray(messages) || messages.length === 0) {
    return [{ type: "text", text: "ok" }];
  }

  const parts = [];

  // 收集 system messages (合并)
  const systems = messages
    .filter((m) => m && m.role === "system")
    .map((m) => (typeof m.content === "string" ? m.content : ""))
    .filter(Boolean);

  // 收集对话 (user/assistant 交错 · 转为简单文本)
  const turns = [];
  for (const m of messages) {
    if (!m || m.role === "system") continue;
    const content = typeof m.content === "string" ? m.content : "";
    if (!content) continue;
    if (m.role === "user") {
      turns.push(`User: ${content}`);
    } else if (m.role === "assistant") {
      turns.push(`Assistant: ${content}`);
    } else {
      turns.push(content);
    }
  }

  // 合并: system + dialog history + 末提示
  let text = "";
  if (systems.length > 0) {
    text += systems.join("\n\n") + "\n\n";
  }
  if (turns.length > 0) {
    text += turns.join("\n\n");
  }
  if (!text) text = "ok";

  parts.push({ type: "text", text });
  return parts;
}

/**
 * session/update → text delta (若 agent_message_chunk · 否则 null)
 *
 *   content 可能形态:
 *     {type:"text", text:"chunk"}
 *     [{type:"text", text:"chunk"}, ...]
 *     "chunk" (旧版)
 */
function extractDelta(update) {
  if (!update || typeof update !== "object") return null;
  const upType = update.sessionUpdate || update.type;
  if (upType !== UPDATE_AGENT_MESSAGE) return null;

  const content = update.content;
  if (!content) return null;

  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((c) => c && c.type === "text" && typeof c.text === "string")
      .map((c) => c.text)
      .join("");
  }
  if (typeof content === "object") {
    if (content.type === "text" && typeof content.text === "string") {
      return content.text;
    }
  }
  return null;
}

// ════════════════════════════════════════════════════════════════
// §4  wss 单笔 chat · 完整 ACP 全路
// ════════════════════════════════════════════════════════════════

/**
 * 主入口 · 与 cloud_engine.chat 同签名
 *
 * @param {Object} state - { apiKey, account, ... }
 * @param {string} modelUid - OpenAI model (Devin Cloud 不选 model · 仅记录)
 * @param {Array} messages - OpenAI messages
 * @param {Function} onDelta - (text) => void · SSE chunk callback
 * @param {Array} staticModels - 兼容 cloud_engine 签名 · 此处不用
 * @param {Object} opts - { timeoutMs?, signal?, _debug? }
 * @returns {Promise<{text, tokens, model, host, durationMs, _engine}>}
 */
async function chat(
  state,
  modelUid,
  messages,
  onDelta,
  staticModels = [],
  opts = {},
) {
  if (typeof globalThis.WebSocket !== "function") {
    throw new Error(
      `Devin Cloud 路需 Node 22+ 内置 WebSocket · 当前 ${process.version}`,
    );
  }
  if (!state || typeof state.apiKey !== "string" || state.apiKey.length < 30) {
    throw new Error("Devin Cloud 路需 state.apiKey (devin-session-token$JWT)");
  }
  if (!state.apiKey.startsWith(TOKEN_PREFIX)) {
    throw new Error(
      `Devin Cloud 路仅接 devin-session-token$ 型 · 当前 prefix=${state.apiKey.slice(0, 8)}...`,
    );
  }

  const timeoutMs = opts.timeoutMs || DEFAULT_TIMEOUT_MS;
  const t0 = Date.now();
  const wssUrl = buildWssUrl(state.apiKey);
  const wssUrlSafe = wssUrl.replace(/token=[^&]+/, "token=<JWT_REDACTED>");

  if (opts._debug)
    _log(
      `account=${state.account || "?"} key=${maskToken(state.apiKey)} target=${wssUrlSafe}`,
    );

  return new Promise((resolve, reject) => {
    let ws;
    try {
      ws = new WebSocket(wssUrl);
    } catch (e) {
      reject(new Error(`Devin Cloud wss 建失: ${e.message}`));
      return;
    }

    let _closed = false;
    let _resolved = false;
    let initOk = false;
    let sessionId = null;
    let stopReason = null;
    let usage = null;
    let collectedText = "";
    let updateCount = 0;
    let firstChunkAt = null;
    let promptStartAt = 0;

    const cleanup = (err, result) => {
      if (_resolved) return;
      _resolved = true;
      if (!_closed) {
        try {
          ws.close(1000, "chat done");
        } catch {}
      }
      if (err) reject(err);
      else resolve(result);
    };

    // 兜底超时
    const timer = setTimeout(() => {
      cleanup(
        new Error(
          `Devin Cloud wss 超时 ${timeoutMs}ms · ` +
            `sessionId=${sessionId || "(none)"} updates=${updateCount} ` +
            `firstChunkMs=${firstChunkAt || "(none)"}`,
        ),
      );
    }, timeoutMs);

    // abort 信号 (opts.signal)
    if (opts.signal && typeof opts.signal.addEventListener === "function") {
      opts.signal.addEventListener("abort", () => {
        clearTimeout(timer);
        cleanup(new Error("Devin Cloud wss aborted"));
      });
    }

    const send = (obj) => {
      try {
        ws.send(JSON.stringify(obj));
      } catch (e) {
        if (opts._debug) _log(`send fail [${obj.method}]: ${e.message}`);
      }
    };

    ws.onopen = () => {
      if (opts._debug) _log(`wss open · ${Date.now() - t0}ms`);
      send({
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: 1,
          clientCapabilities: {
            fs: { readTextFile: true, writeTextFile: true },
            elicitation: { form: {} },
            _meta: {
              "cognition.ai/subagentSupport": false,
              "cognition.ai/multiRootWorkspace": false,
              "cognition.ai/partialContent": false,
              "cognition.ai/messageGrouping": false,
            },
          },
        },
      });
    };

    ws.onerror = (ev) => {
      const msg = ev?.message || ev?.error?.message || "(unknown error)";
      clearTimeout(timer);
      cleanup(new Error(`Devin Cloud wss error: ${msg}`));
    };

    ws.onclose = (ev) => {
      _closed = true;
      clearTimeout(timer);
      if (_resolved) return;
      // 未 resolve 即 close · 可能是上游主动断 (auth 失/quota 等)
      const reason = (ev?.reason || "").slice(0, 200);
      const code = ev?.code;
      if (collectedText && stopReason) {
        // 已收到内容 + stopReason · 视为正常完
        cleanup(null, {
          text: collectedText,
          tokens: usage?.totalTokens || 0,
          quotaCostBp: 0,
          model: modelUid || "devin-cloud-agent",
          host: WSS_BASE,
          durationMs: Date.now() - t0,
          _engine: "devin-cloud",
          stopReason,
          usage,
        });
      } else {
        cleanup(
          new Error(
            `Devin Cloud wss closed prematurely · code=${code} reason="${reason}" ` +
              `sessionId=${sessionId || "(none)"} updates=${updateCount}`,
          ),
        );
      }
    };

    ws.onmessage = (ev) => {
      let raw = ev.data;
      if (raw instanceof ArrayBuffer) raw = Buffer.from(raw).toString("utf8");
      if (Buffer.isBuffer(raw)) raw = raw.toString("utf8");
      if (typeof raw !== "string") return;

      // ACP messages 一笔一行 (JSON-RPC)
      const lines = raw.split("\n").filter((x) => x.trim());
      for (const line of lines) {
        let parsed;
        try {
          parsed = JSON.parse(line);
        } catch {
          continue;
        }
        handleMsg(parsed);
      }
    };

    function handleMsg(msg) {
      // session/update notification (无 id · 流式 chat 载体)
      if (msg.method === "session/update") {
        updateCount++;
        const update = msg.params?.update;
        const upType = update?.sessionUpdate || update?.type;

        if (upType === UPDATE_AGENT_MESSAGE) {
          const delta = extractDelta(update);
          if (delta) {
            if (!firstChunkAt) firstChunkAt = Date.now() - promptStartAt;
            collectedText += delta;
            try {
              if (typeof onDelta === "function") onDelta(delta);
            } catch (e) {
              if (opts._debug) _log(`onDelta err: ${e.message}`);
            }
          }
        }
        // agent_thought_chunk · session_info_update 等不算 chat 输出 · 跳
        if (update?.stopReason) stopReason = update.stopReason;
        if (update?.usage) usage = update.usage;
        return;
      }

      // RPC response
      const id = msg.id;

      if (id === 1) {
        if (msg.error) {
          clearTimeout(timer);
          cleanup(
            new Error(
              `Devin Cloud initialize 失 [${msg.error.code}] ${msg.error.message}`,
            ),
          );
          return;
        }
        initOk = true;
        const authMethods = msg.result?.authMethods?.map((a) => a.id) || [];
        if (opts._debug)
          _log(`initialize ok · authMethods=${JSON.stringify(authMethods)}`);

        // wss 路 authMethods=[] · skip authenticate · 直 session/new
        // (stdio chisel 路才需 authenticate · wss URL token 已前置)
        if (authMethods.length > 0) {
          // 反向兼容 stdio (一般不会到此)
          send({
            jsonrpc: "2.0",
            id: 2,
            method: "authenticate",
            params: {
              methodId: "windsurf-api-key",
              _meta: {
                api_key: state.apiKey,
                api_server_url:
                  state.apiServerUrl ||
                  "https://server.self-serve.windsurf.com",
              },
            },
          });
        } else {
          // 直 session/new
          sendSessionNew();
        }
        return;
      }

      if (id === 2) {
        if (msg.error) {
          clearTimeout(timer);
          cleanup(
            new Error(
              `Devin Cloud authenticate 失 [${msg.error.code}] ${msg.error.message}`,
            ),
          );
          return;
        }
        sendSessionNew();
        return;
      }

      if (id === 3) {
        if (msg.error) {
          clearTimeout(timer);
          cleanup(
            new Error(
              `Devin Cloud session/new 失 [${msg.error.code}] ${msg.error.message}`,
            ),
          );
          return;
        }
        sessionId = msg.result?.sessionId;
        if (!sessionId) {
          clearTimeout(timer);
          cleanup(new Error("Devin Cloud session/new 返但无 sessionId"));
          return;
        }
        if (opts._debug) _log(`session/new ok · sessionId=${sessionId}`);
        sendSessionPrompt();
        return;
      }

      if (id === 4) {
        if (msg.error) {
          clearTimeout(timer);
          cleanup(
            new Error(
              `Devin Cloud session/prompt 失 [${msg.error.code}] ${msg.error.message}`,
            ),
          );
          return;
        }
        const result = msg.result || {};
        if (result.stopReason) stopReason = result.stopReason;
        if (result.usage) usage = result.usage;
        clearTimeout(timer);
        cleanup(null, {
          text: collectedText,
          tokens: usage?.totalTokens || 0,
          quotaCostBp: 0,
          model: modelUid || "devin-cloud-agent",
          host: WSS_BASE,
          durationMs: Date.now() - t0,
          _engine: "devin-cloud",
          stopReason,
          usage,
          updateCount,
          firstChunkMs: firstChunkAt,
        });
        return;
      }
    }

    function sendSessionNew() {
      send({
        jsonrpc: "2.0",
        id: 3,
        method: "session/new",
        params: {
          cwd: opts.cwd || DEFAULT_CWD,
          mcpServers: [],
        },
      });
    }

    function sendSessionPrompt() {
      promptStartAt = Date.now();
      send({
        jsonrpc: "2.0",
        id: 4,
        method: "session/prompt",
        params: {
          sessionId,
          prompt: messagesToPrompt(messages),
        },
      });
    }
  });
}

// ════════════════════════════════════════════════════════════════
// §5  健康检 · 一笔 handshake (no prompt) 验通路 (DAO_DEVIN_CLOUD_HEALTH=1 时)
// ════════════════════════════════════════════════════════════════

async function healthCheck(state, opts = {}) {
  const timeoutMs = opts.timeoutMs || 30000;
  if (
    !state ||
    typeof state.apiKey !== "string" ||
    !state.apiKey.startsWith(TOKEN_PREFIX)
  ) {
    return { ok: false, error: "apiKey 不为 devin-session-token$ 型" };
  }
  if (typeof globalThis.WebSocket !== "function") {
    return { ok: false, error: "Node 内 WebSocket 不在 · 须 Node 22+" };
  }

  const t0 = Date.now();
  return new Promise((resolve) => {
    let ws;
    try {
      ws = new WebSocket(buildWssUrl(state.apiKey));
    } catch (e) {
      resolve({ ok: false, error: `wss 建失: ${e.message}` });
      return;
    }
    const timer = setTimeout(() => {
      try {
        ws.close(1000, "health timeout");
      } catch {}
      resolve({ ok: false, error: `health timeout ${timeoutMs}ms` });
    }, timeoutMs);
    ws.onopen = () => {
      try {
        ws.send(
          JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "initialize",
            params: {
              protocolVersion: 1,
              clientCapabilities: {
                fs: { readTextFile: true, writeTextFile: true },
              },
            },
          }),
        );
      } catch {}
    };
    ws.onmessage = (ev) => {
      let raw = ev.data;
      if (Buffer.isBuffer(raw)) raw = raw.toString("utf8");
      if (raw instanceof ArrayBuffer) raw = Buffer.from(raw).toString("utf8");
      try {
        const m = JSON.parse((raw + "").split("\n")[0]);
        if (m.id === 1 && m.result) {
          clearTimeout(timer);
          try {
            ws.close(1000, "health ok");
          } catch {}
          resolve({
            ok: true,
            durationMs: Date.now() - t0,
            agentInfo: m.result.agentInfo || null,
            authMethods: (m.result.authMethods || []).map((a) => a.id),
          });
        }
      } catch {}
    };
    ws.onerror = (ev) => {
      clearTimeout(timer);
      resolve({
        ok: false,
        error: `wss error: ${ev?.message || "(unknown)"}`,
      });
    };
    ws.onclose = (ev) => {
      clearTimeout(timer);
      if (ev?.code !== 1000) {
        resolve({ ok: false, error: `wss closed early · code=${ev?.code}` });
      }
    };
  });
}

// ════════════════════════════════════════════════════════════════
// §6  exports · 与 cloud_engine.js 同口风
// ════════════════════════════════════════════════════════════════

module.exports = {
  chat,
  healthCheck,
  // 辅助 · 单元测可见
  _tokenToJwt: tokenToJwt,
  _buildWssUrl: buildWssUrl,
  _messagesToPrompt: messagesToPrompt,
  _extractDelta: extractDelta,
  WSS_BASE,
  TOKEN_PREFIX,
};

// ════════════════════════════════════════════════════════════════
// §7  CLI 自测 (node devin_cloud_engine.js [--prompt "..."])
// ════════════════════════════════════════════════════════════════

if (require.main === module) {
  (async () => {
    const args = process.argv.slice(2);
    const idx = args.indexOf("--prompt");
    const prompt =
      idx >= 0 && args[idx + 1] ? args[idx + 1] : "one word: PONG";

    // 取 ~/.dao/accounts.json active devin
    const accountsPath = path.join(os.homedir(), ".dao", "accounts.json");
    if (!fs.existsSync(accountsPath)) {
      console.error("✗ ~/.dao/accounts.json 不存");
      process.exit(2);
    }
    const db = JSON.parse(fs.readFileSync(accountsPath, "utf8"));
    const acct =
      db.accounts.find((x) => x.email === db.active && x.type === "devin") ||
      db.accounts.find((x) => x.type === "devin");
    if (!acct) {
      console.error("✗ accounts.json 无 devin 账号");
      process.exit(2);
    }

    console.error(
      `[cli] account: ${acct.email} · key: ${maskToken(acct.apiKey)}`,
    );
    console.error(`[cli] prompt: "${prompt}"`);

    try {
      const t0 = Date.now();
      const out = await chat(
        { apiKey: acct.apiKey, account: acct.email },
        "devin-cloud-agent",
        [{ role: "user", content: prompt }],
        (delta) => process.stdout.write(delta),
        [],
        { _debug: true, timeoutMs: 90000 },
      );
      console.error("");
      console.error(`[cli] ✓ ${Date.now() - t0}ms`);
      console.error(`[cli]   text-len: ${out.text.length}`);
      console.error(`[cli]   stopReason: ${out.stopReason}`);
      console.error(`[cli]   firstChunkMs: ${out.firstChunkMs}`);
      console.error(`[cli]   updateCount: ${out.updateCount}`);
      console.error(`[cli]   tokens: ${out.tokens}`);
      process.exit(0);
    } catch (e) {
      console.error("");
      console.error(`[cli] ✗ ${e.message}`);
      process.exit(1);
    }
  })();
}
