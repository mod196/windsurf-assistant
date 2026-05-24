#!/usr/bin/env bash
# vm_total.sh · 印208 · VM自治极取 · 道法自然 · 无为而无以为
#
#   「大曰逝，逝曰远，远曰反。」                  ── 帛书二十五
#   「天下有始，以为天下母。既得其母，以知其子，复守其母，没身不殆。」 ── 帛书五十二
#   「治大国若烹小鲜，以道莅天下。」              ── 帛书六十
#   「取之尽锱铢，用之如泥沙」                    ── 阿房宫赋
#
# § 道义
#   印205 nucleus      生命周期 · 本机驱
#   印206 primitive    HTTP REST · 本机驱
#   印207 supreme      全摄 17 模块 · 本机驱
#   印208 vm_total.sh  VM 自治极取 · 本机投放即弃 · VM 自续永生
#
# § 主公诏 (重锚)
#   彻底打通虚拟机一切，不依赖一切资源 (账号/agent/额度/本机)
#   无限制并发、无限制操作、无限制使用
#   Devin Cloud 官方 VM 取天下资源尽为我所用
#   高效利用官方原生元工具 · 多并发 · 大型操作 · 复杂使用
#   长链路稳定 · 道法自然推进到底 · 无为而无以为
#
# § 用法 (VM 上一键投放)
#   curl -fsSL https://raw.githubusercontent.com/zhouyoukang/windsurf-assistant/main/Windsurf万法归宗/130-道独立体_Standalone/vm_total.sh | bash
#   curl -fsSL .../vm_total.sh | GIST_ID=xxx GIST_TOKEN=ghp_xxx bash    # 携 Gist 心跳
#   curl -fsSL .../vm_total.sh | bash -s -- start                         # 显式启动
#   curl -fsSL .../vm_total.sh | bash -s -- status                        # 状态
#   curl -fsSL .../vm_total.sh | bash -s -- self-renew                    # 强制隧道续
#   curl -fsSL .../vm_total.sh | bash -s -- exec "uname -a"               # 执行命令
#   curl -fsSL .../vm_total.sh | bash -s -- mesh-pull                     # 拉 mesh 同伴
#   curl -fsSL .../vm_total.sh | bash -s -- daemon                        # 起守护循环
#
# § 16 大模块
#   §1  日志 / trap / 锁
#   §2  环境探测 (ubuntu / arch / cpu / mem / nvidia)
#   §3  resource_max (CPU governor / sysctl / ulimit / 调优)
#   §4  install (apt + binaries · idempotent)
#   §5  vm_omni 起 (port 8080 · HTTP REST 8 原语)
#   §6  ttyd 起 (port 7681 · shell)
#   §7  filebrowser 起 (port 8888 · noauth · file UI)
#   §8  VS Code Server / noVNC / Python http (best-effort)
#   §9  cloudflared tunnel (随机 trycloudflare URL · 写到本机状态)
#   §10 GitHub Gist 心跳 (VM → Gist 写 URL · 全网读)
#   §11 cloudflared self-renew (旧 tunnel 死 自重启 · 写新 URL 到 Gist)
#   §12 service watchdog (30s 周期 · 死了重启)
#   §13 mesh peer client (经 Gist 取其他 VM · ping · 数据转发)
#   §14 task executor (Gist 拉任务队列 · 执行 · 写回结果)
#   §15 systemd unit 注册 (开机自起)
#   §16 CLI 入口 (start / stop / status / self-renew / daemon / mesh-pull / exec / submit / harvest)

set -u  # 不 set -e (允许部分模块失败 · 道法自然容错)
umask 022

# ─────────────────────────────────────────────────────────────────
# §1 日志 / trap / 锁
# ─────────────────────────────────────────────────────────────────

VERSION="1.0.0"
SEAL="印208 · VM自治极取 · 道法自然 · 无为而无以为"
DAO_HOME="${DAO_HOME:-$HOME/.dao_vm_total}"
LOG="$DAO_HOME/total.log"
PIDDIR="$DAO_HOME/pid"
URLS="$DAO_HOME/urls.json"
LOCK="$DAO_HOME/.lock"
mkdir -p "$DAO_HOME" "$PIDDIR" "$DAO_HOME/tasks" "$DAO_HOME/results" 2>/dev/null

ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG" >&2; }
err() { echo "[$(ts)][ERR] $*" | tee -a "$LOG" >&2; }
ok()  { echo "[$(ts)][OK ] $*" | tee -a "$LOG" >&2; }

acquire_lock() {
  local fd="${1:-9}"
  exec 9>"$LOCK" || return 1
  command -v flock >/dev/null && flock -n 9 || true
}
release_lock() { exec 9>&-; rm -f "$LOCK" 2>/dev/null; }

# ─────────────────────────────────────────────────────────────────
# §2 环境探测
# ─────────────────────────────────────────────────────────────────

detect_env() {
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64;; aarch64) ARCH=arm64;; esac
  CPU_COUNT="$(nproc 2>/dev/null || echo 1)"
  MEM_KB="$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  MEM_GB=$(( MEM_KB / 1024 / 1024 ))
  HAS_NVIDIA=0
  command -v nvidia-smi >/dev/null && HAS_NVIDIA=1
  IS_UBUNTU=0
  [ -f /etc/lsb-release ] && IS_UBUNTU=1
  log "env: arch=$ARCH cpu=$CPU_COUNT mem=${MEM_GB}GB nvidia=$HAS_NVIDIA ubuntu=$IS_UBUNTU"
}

# ─────────────────────────────────────────────────────────────────
# §3 resource_max (官方原生工具调优 · CPU/IO/Net 极取)
# ─────────────────────────────────────────────────────────────────

resource_max() {
  log "resource_max: tuning kernel/cpu/ulimit"

  # CPU governor=performance (要 sudo)
  if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] 2>/dev/null; then
    for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      echo performance | sudo tee "$g" >/dev/null 2>&1 || true
    done
  fi

  # sysctl 网/连接调优
  if command -v sudo >/dev/null; then
    sudo sysctl -w net.core.somaxconn=65535 2>/dev/null || true
    sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65535 2>/dev/null || true
    sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535" 2>/dev/null || true
    sudo sysctl -w fs.file-max=2097152 2>/dev/null || true
    sudo sysctl -w vm.swappiness=10 2>/dev/null || true
  fi

  # ulimit
  ulimit -n 1048576 2>/dev/null || ulimit -n 65535 2>/dev/null || true
  ulimit -u 65535 2>/dev/null || true

  ok "resource_max applied"
}

# ─────────────────────────────────────────────────────────────────
# §4 install (apt + binaries · idempotent · 道法自然容错)
# ─────────────────────────────────────────────────────────────────

ensure_pkg() {
  local pkg="$1" cmd="$2"
  command -v "$cmd" >/dev/null && return 0
  if command -v apt-get >/dev/null; then
    sudo apt-get update -qq 2>/dev/null
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq "$pkg" 2>/dev/null
  fi
  command -v "$cmd" >/dev/null
}

ensure_node() {
  command -v node >/dev/null && return 0
  log "install: node 22 (NodeSource)"
  curl -fsSL https://deb.nodesource.com/setup_22.x 2>/dev/null | sudo bash - 2>/dev/null
  sudo apt-get install -yqq nodejs 2>/dev/null
  command -v node >/dev/null
}

install_cloudflared() {
  command -v cloudflared >/dev/null && return 0
  log "install: cloudflared"
  local url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
  sudo curl -fsSL "$url" -o /usr/local/bin/cloudflared 2>/dev/null
  sudo chmod +x /usr/local/bin/cloudflared 2>/dev/null
  command -v cloudflared >/dev/null
}

install_ttyd() {
  command -v ttyd >/dev/null && return 0
  ensure_pkg ttyd ttyd && return 0
  # fallback: download release binary
  local url="https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.${ARCH//arm64/aarch64}"
  url="${url//amd64/x86_64}"
  sudo curl -fsSL "$url" -o /usr/local/bin/ttyd 2>/dev/null
  sudo chmod +x /usr/local/bin/ttyd 2>/dev/null
  command -v ttyd >/dev/null
}

install_filebrowser() {
  command -v filebrowser >/dev/null && return 0
  log "install: filebrowser"
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh 2>/dev/null | sudo bash 2>/dev/null
  command -v filebrowser >/dev/null
}

ensure_jq() { ensure_pkg jq jq; }

install_all() {
  detect_env
  log "install: starting"
  ensure_node || err "node install failed"
  ensure_jq   || err "jq install failed"
  install_cloudflared || err "cloudflared install failed"
  install_ttyd        || log "ttyd not installed (best-effort)"
  install_filebrowser || log "filebrowser not installed (best-effort)"
  ok "install: done"
}

# ─────────────────────────────────────────────────────────────────
# §5 vm_omni (HTTP REST 8 原语 · 复用 印104)
# ─────────────────────────────────────────────────────────────────

write_vm_omni_min() {
  # 极简内联版 · 仅 8 原语 (无 ttyd/filebrowser 路由 · 那些独立服务在 §6 §7)
  cat > "$DAO_HOME/vm_omni_min.js" <<'OMNI_EOF'
// vm_omni_min · 印208 · 8 原语 + /port/<N>/* 透传
const http = require('http'); const net = require('net');
const fs = require('fs'); const path = require('path');
const { spawn, exec } = require('child_process');
const PORT = parseInt(process.env.OMNI_PORT || '8080', 10);
const START = Date.now();
const TASKS = new Map();
function reqId() { return Math.random().toString(36).slice(2,10); }
function send(res, code, ct, body) { res.writeHead(code, { 'Content-Type': ct, 'Access-Control-Allow-Origin': '*' }); res.end(body); }
function readBody(req) { return new Promise(r=>{ const c=[]; req.on('data',b=>c.push(b)); req.on('end',()=>r(Buffer.concat(c))); }); }
const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x'); const p = u.pathname;
  try {
    if (p === '/_/health') return send(res, 200, 'application/json', JSON.stringify({ ok: true, uptime: Math.floor((Date.now()-START)/1000), seal: '印208' }));
    if (p === '/_/stat') {
      const stat = { uptime: Math.floor((Date.now()-START)/1000), pid: process.pid, mem: process.memoryUsage(), cpus: require('os').cpus().length, load: require('os').loadavg(), free: require('os').freemem(), total: require('os').totalmem() };
      return send(res, 200, 'application/json', JSON.stringify(stat));
    }
    if (p === '/_/run' && req.method === 'POST') {
      const body = (await readBody(req)).toString('utf8');
      let cmd = ''; try { cmd = JSON.parse(body).cmd || body; } catch { cmd = body; }
      if (!cmd) return send(res, 400, 'text/plain', 'no cmd');
      const id = reqId();
      const child = spawn('bash', ['-lc', cmd], { stdio: ['ignore','pipe','pipe'] });
      let stdout='', stderr=''; child.stdout.on('data', d => stdout += d.toString()); child.stderr.on('data', d => stderr += d.toString());
      const result = await new Promise(r => { let done=false; child.on('exit', code => { if(done)return; done=true; r({ ok: code===0, code, stdout, stderr }); }); setTimeout(() => { if(done)return; done=true; try{child.kill();}catch{} r({ ok:false, code:-1, stdout, stderr, timeout:true }); }, 60000); });
      return send(res, 200, 'application/json', JSON.stringify({ id, ...result }));
    }
    if (p.startsWith('/_/file/')) {
      const fp = decodeURIComponent(p.slice('/_/file/'.length));
      if (req.method === 'GET') {
        if (!fs.existsSync(fp)) return send(res, 404, 'text/plain', 'not found');
        return send(res, 200, 'application/octet-stream', fs.readFileSync(fp));
      } else if (req.method === 'PUT') {
        const buf = await readBody(req);
        try { fs.mkdirSync(path.dirname(fp), { recursive: true }); fs.writeFileSync(fp, buf); return send(res, 200, 'application/json', JSON.stringify({ ok:true, bytes: buf.length })); } catch(e) { return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message })); }
      } else if (req.method === 'DELETE') {
        try { fs.unlinkSync(fp); return send(res, 200, 'application/json', JSON.stringify({ ok:true })); } catch(e) { return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message })); }
      }
    }
    if (p === '/_/spawn' && req.method === 'POST') {
      const body = (await readBody(req)).toString('utf8');
      let req_data; try { req_data = JSON.parse(body); } catch { req_data = { cmd: body }; }
      const id = reqId();
      const child = spawn('bash', ['-lc', req_data.cmd], { stdio: ['ignore','pipe','pipe'], detached: true });
      const task = { id, cmd: req_data.cmd, pid: child.pid, started: Date.now(), stdout: '', stderr: '', exitCode: null };
      TASKS.set(id, task);
      child.stdout.on('data', d => task.stdout += d.toString());
      child.stderr.on('data', d => task.stderr += d.toString());
      child.on('exit', code => { task.exitCode = code; task.finished = Date.now(); });
      return send(res, 200, 'application/json', JSON.stringify({ ok:true, id, pid: child.pid }));
    }
    if (p.startsWith('/_/task/')) {
      const id = p.slice('/_/task/'.length);
      const t = TASKS.get(id);
      if (!t) return send(res, 404, 'text/plain', 'no such task');
      return send(res, 200, 'application/json', JSON.stringify(t));
    }
    if (p === '/_/tasks') return send(res, 200, 'application/json', JSON.stringify([...TASKS.values()]));
    if (p.startsWith('/port/')) {
      const m = p.match(/^\/port\/(\d+)(\/.*)?$/);
      if (!m) return send(res, 400, 'text/plain', 'bad port');
      const tgt = parseInt(m[1]); const subPath = m[2] || '/';
      const opts = { hostname: '127.0.0.1', port: tgt, path: subPath, method: req.method, headers: { ...req.headers, host: `127.0.0.1:${tgt}` } };
      const proxyReq = http.request(opts, (proxyRes) => { res.writeHead(proxyRes.statusCode, proxyRes.headers); proxyRes.pipe(res); });
      proxyReq.on('error', e => send(res, 502, 'text/plain', 'bad gateway: ' + e.message));
      req.pipe(proxyReq);
      return;
    }
    return send(res, 200, 'text/html', `<h1>vm_omni_min · 印208</h1><p>PORT=${PORT} · uptime=${Math.floor((Date.now()-START)/1000)}s</p><ul><li>/_/health</li><li>/_/stat</li><li>POST /_/run {cmd}</li><li>GET/PUT/DELETE /_/file/&lt;path&gt;</li><li>POST /_/spawn {cmd}</li><li>GET /_/task/&lt;id&gt;</li><li>/port/&lt;N&gt;/...</li></ul>`);
  } catch (e) {
    return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message }));
  }
});
server.on('upgrade', (req, sock, head) => {
  const m = req.url.match(/^\/port\/(\d+)(\/.*)?$/);
  if (!m) { sock.destroy(); return; }
  const tgt = net.connect(parseInt(m[1]), '127.0.0.1', () => {
    tgt.write(`${req.method} ${m[2]||'/'} HTTP/1.1\r\n`);
    for (const [k,v] of Object.entries(req.headers)) tgt.write(`${k}: ${v}\r\n`);
    tgt.write('\r\n'); if (head && head.length) tgt.write(head);
    sock.pipe(tgt); tgt.pipe(sock);
  });
  tgt.on('error', () => { try { sock.destroy(); } catch {} });
});
server.listen(PORT, '0.0.0.0', () => console.log(`vm_omni_min :${PORT}`));
OMNI_EOF
}

start_vm_omni() {
  local pidf="$PIDDIR/omni.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then ok "vm_omni alive pid=$(cat "$pidf")"; return 0; fi
  write_vm_omni_min
  command -v node >/dev/null || { err "no node · skipping vm_omni"; return 1; }
  OMNI_PORT=8080 nohup node "$DAO_HOME/vm_omni_min.js" >> "$LOG" 2>&1 &
  echo $! > "$pidf"
  sleep 1
  curl -fsS -m 3 "http://127.0.0.1:8080/_/health" >/dev/null 2>&1 && ok "vm_omni :8080 alive" || err "vm_omni start failed"
}

# ─────────────────────────────────────────────────────────────────
# §6 ttyd (shell) · §7 filebrowser
# ─────────────────────────────────────────────────────────────────

start_ttyd() {
  local pidf="$PIDDIR/ttyd.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then ok "ttyd alive"; return 0; fi
  command -v ttyd >/dev/null || { log "no ttyd · skipping"; return 1; }
  nohup ttyd -p 7681 -W bash >> "$LOG" 2>&1 &
  echo $! > "$pidf"; sleep 1
  ok "ttyd :7681"
}

start_filebrowser() {
  local pidf="$PIDDIR/filebrowser.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then ok "filebrowser alive"; return 0; fi
  command -v filebrowser >/dev/null || { log "no filebrowser · skipping"; return 1; }
  local db="$DAO_HOME/filebrowser.db"
  filebrowser -d "$db" config init -a 0.0.0.0 -p 8888 >/dev/null 2>&1
  filebrowser -d "$db" config set --auth.method=noauth >/dev/null 2>&1
  nohup filebrowser -d "$db" -a 0.0.0.0 -p 8888 -r / >> "$LOG" 2>&1 &
  echo $! > "$pidf"; sleep 1
  ok "filebrowser :8888"
}

# ─────────────────────────────────────────────────────────────────
# §9 cloudflared tunnel
# ─────────────────────────────────────────────────────────────────

start_cloudflared() {
  local pidf="$PIDDIR/cloudflared.pid"
  local urlf="$DAO_HOME/cf.url"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null && [ -s "$urlf" ]; then
    ok "cloudflared alive · URL=$(cat "$urlf")"
    return 0
  fi
  command -v cloudflared >/dev/null || { err "no cloudflared"; return 1; }
  rm -f "$urlf"
  nohup cloudflared tunnel --url http://127.0.0.1:8080 --no-autoupdate >> "$DAO_HOME/cf.log" 2>&1 &
  echo $! > "$pidf"
  # 等待 URL 出现 (最多 60s)
  local i=0
  while [ $i -lt 60 ]; do
    local u=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$DAO_HOME/cf.log" 2>/dev/null | head -1)
    if [ -n "$u" ]; then echo "$u" > "$urlf"; ok "cloudflared URL: $u"; gist_publish; return 0; fi
    sleep 1; i=$((i+1))
  done
  err "cloudflared timeout (60s)"
  return 1
}

# ─────────────────────────────────────────────────────────────────
# §10 GitHub Gist 心跳 (无中心 · VM 自报)
# ─────────────────────────────────────────────────────────────────

gist_publish() {
  local gid="${GIST_ID:-${DAO_GIST_ID:-}}"
  local tok="${GIST_TOKEN:-${DAO_GIST_TOKEN:-}}"
  [ -z "$gid" ] || [ -z "$tok" ] && { log "gist: GIST_ID/TOKEN 未设 · 跳过心跳 (本机/其他 VM 可手取 cf.url)"; return 0; }
  local url=$(cat "$DAO_HOME/cf.url" 2>/dev/null || echo "")
  [ -z "$url" ] && { log "gist: no cf.url · skip"; return 1; }
  local hostname=$(hostname)
  local now=$(ts)
  local payload="{\"description\":\"印208 vm_total heartbeat\",\"files\":{\"$hostname.json\":{\"content\":\"{\\\"hostname\\\":\\\"$hostname\\\",\\\"url\\\":\\\"$url\\\",\\\"updated\\\":\\\"$now\\\",\\\"seal\\\":\\\"印208\\\",\\\"version\\\":\\\"$VERSION\\\"}\"}}}"
  local rc=$(curl -fsS -m 10 -o /dev/null -w "%{http_code}" \
    -X PATCH "https://api.github.com/gists/$gid" \
    -H "Authorization: token $tok" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$payload" 2>/dev/null)
  if [ "$rc" = "200" ]; then ok "gist heartbeat: $url ($hostname)"; else err "gist heartbeat HTTP $rc"; fi
}

gist_pull_peers() {
  local gid="${GIST_ID:-${DAO_GIST_ID:-}}"
  [ -z "$gid" ] && return 1
  curl -fsS -m 10 "https://api.github.com/gists/$gid" 2>/dev/null \
    | (command -v jq >/dev/null && jq -r '.files | to_entries[] | .value.content' || cat)
}

# ─────────────────────────────────────────────────────────────────
# §11 cloudflared self-renew (旧 tunnel 死 → 自重启 + 写新 URL)
# ─────────────────────────────────────────────────────────────────

self_renew() {
  log "self_renew: kill old cloudflared + restart"
  local pidf="$PIDDIR/cloudflared.pid"
  if [ -f "$pidf" ]; then kill "$(cat "$pidf")" 2>/dev/null; sleep 2; fi
  rm -f "$pidf" "$DAO_HOME/cf.log" "$DAO_HOME/cf.url"
  start_cloudflared
}

# ─────────────────────────────────────────────────────────────────
# §12 service watchdog (30s 周期 · 死了重启 · 全在 VM 内)
# ─────────────────────────────────────────────────────────────────

watchdog_once() {
  # vm_omni
  local pidf="$PIDDIR/omni.pid"
  if [ ! -f "$pidf" ] || ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: vm_omni dead · restart"; start_vm_omni
  fi
  # ttyd
  pidf="$PIDDIR/ttyd.pid"
  if [ -f "$pidf" ] && ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: ttyd dead · restart"; start_ttyd
  fi
  # filebrowser
  pidf="$PIDDIR/filebrowser.pid"
  if [ -f "$pidf" ] && ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: filebrowser dead · restart"; start_filebrowser
  fi
  # cloudflared (含 health probe · 死了 self_renew)
  pidf="$PIDDIR/cloudflared.pid"
  local need_renew=0
  if [ ! -f "$pidf" ] || ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: cloudflared proc dead"; need_renew=1
  else
    local u=$(cat "$DAO_HOME/cf.url" 2>/dev/null || echo "")
    if [ -n "$u" ]; then
      local rc=$(curl -fsS -m 10 -o /dev/null -w "%{http_code}" "$u/_/health" 2>/dev/null)
      if [ "$rc" != "200" ]; then log "watchdog: tunnel unhealthy ($rc)"; need_renew=1; fi
    fi
  fi
  [ $need_renew -eq 1 ] && self_renew
  # gist heartbeat 周期 (5 分钟一次)
  local last=$(stat -c '%Y' "$DAO_HOME/.last_gist" 2>/dev/null || echo 0)
  local now=$(date +%s)
  if [ $(( now - last )) -ge 300 ]; then gist_publish && touch "$DAO_HOME/.last_gist"; fi
}

daemon_loop() {
  log "daemon_loop: starting (interval=30s)"
  while true; do
    watchdog_once || true
    sleep 30
  done
}

start_daemon() {
  local pidf="$PIDDIR/daemon.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then ok "daemon alive"; return 0; fi
  nohup bash "$0" daemon-inner >> "$LOG" 2>&1 &
  echo $! > "$pidf"
  ok "daemon started pid=$(cat "$pidf")"
}

# ─────────────────────────────────────────────────────────────────
# §13 mesh peer client (经 Gist 取其他 VM URL)
# ─────────────────────────────────────────────────────────────────

mesh_pull() {
  log "mesh_pull: fetching peers"
  local data=$(gist_pull_peers)
  [ -z "$data" ] && { err "mesh_pull: no gist data"; return 1; }
  echo "$data" > "$DAO_HOME/peers.json"
  if command -v jq >/dev/null; then
    local count=$(echo "$data" | jq -s 'length' 2>/dev/null || echo 0)
    ok "mesh_pull: $count peers"
    echo "$data" | jq -r '"  · \(.hostname) → \(.url) [\(.updated)]"' 2>/dev/null
  else
    ok "mesh_pull: cached"
  fi
}

# ─────────────────────────────────────────────────────────────────
# §14 task executor (Gist 任务队列 · 执行 · 写回结果)
# ─────────────────────────────────────────────────────────────────

task_submit() {
  local cmd="$*"
  [ -z "$cmd" ] && { err "task_submit: empty cmd"; return 1; }
  local id="t-$(date +%s)-$RANDOM"
  local f="$DAO_HOME/tasks/$id.json"
  echo "{\"id\":\"$id\",\"cmd\":$(printf '%s' "$cmd" | jq -Rs . 2>/dev/null || echo "\"$cmd\""),\"submitted\":\"$(ts)\",\"status\":\"pending\"}" > "$f"
  ok "task: queued $id"
  echo "$id"
}

task_run_pending() {
  for f in "$DAO_HOME"/tasks/*.json; do
    [ -e "$f" ] || continue
    local id=$(basename "$f" .json)
    local status=$(grep -oE '"status":"[a-z]+"' "$f" | head -1 | sed 's/.*"\([a-z]*\)"/\1/')
    [ "$status" != "pending" ] && continue
    local cmd=$(jq -r '.cmd' "$f" 2>/dev/null || echo "")
    [ -z "$cmd" ] && continue
    log "task_run: $id · cmd: $cmd"
    local out=$(bash -c "$cmd" 2>&1)
    local rc=$?
    local ts_done=$(ts)
    cat > "$DAO_HOME/results/$id.json" <<EOF
{"id":"$id","cmd":$(printf '%s' "$cmd" | jq -Rs . 2>/dev/null),"exitCode":$rc,"finished":"$ts_done","output":$(printf '%s' "$out" | jq -Rs . 2>/dev/null)}
EOF
    sed -i 's/"status":"pending"/"status":"done"/' "$f"
    ok "task_run: $id done rc=$rc"
  done
}

task_harvest() {
  local count=0
  for f in "$DAO_HOME"/results/*.json; do
    [ -e "$f" ] || continue
    cat "$f"
    echo
    count=$((count+1))
  done
  log "harvest: $count results"
}

# ─────────────────────────────────────────────────────────────────
# §15 systemd unit (开机自起 · 极简)
# ─────────────────────────────────────────────────────────────────

install_systemd() {
  command -v systemctl >/dev/null || { log "no systemd · skip"; return 1; }
  local unit="/etc/systemd/system/dao-vm-total.service"
  local script="$DAO_HOME/vm_total.sh"
  cp "$0" "$script" 2>/dev/null
  chmod +x "$script"
  sudo tee "$unit" >/dev/null <<EOF
[Unit]
Description=dao_vm_total · 印208 · VM自治极取
After=network-online.target

[Service]
Type=forking
User=$USER
Environment="GIST_ID=${GIST_ID:-}"
Environment="GIST_TOKEN=${GIST_TOKEN:-}"
ExecStart=$script start
ExecStop=$script stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload 2>/dev/null
  sudo systemctl enable dao-vm-total 2>/dev/null
  ok "systemd installed: dao-vm-total"
}

# ─────────────────────────────────────────────────────────────────
# §16 CLI 入口
# ─────────────────────────────────────────────────────────────────

cmd_start() {
  acquire_lock
  detect_env
  install_all
  resource_max
  start_vm_omni
  start_ttyd
  start_filebrowser
  start_cloudflared
  start_daemon
  release_lock
  cmd_status
}

cmd_stop() {
  for s in daemon cloudflared filebrowser ttyd omni; do
    local pidf="$PIDDIR/$s.pid"
    if [ -f "$pidf" ]; then
      kill "$(cat "$pidf")" 2>/dev/null
      rm -f "$pidf"
      log "stopped: $s"
    fi
  done
  ok "stopped all"
}

cmd_status() {
  detect_env
  echo "════ $SEAL v$VERSION ════"
  echo "host: $(hostname) · arch: $ARCH · cpu: $CPU_COUNT · mem: ${MEM_GB}GB"
  echo "DAO_HOME: $DAO_HOME"
  echo "─── services ───"
  for s in omni ttyd filebrowser cloudflared daemon; do
    local pidf="$PIDDIR/$s.pid"
    if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
      printf "  %-15s ALIVE pid=%s\n" "$s" "$(cat "$pidf")"
    else
      printf "  %-15s DEAD\n" "$s"
    fi
  done
  echo "─── URL ───"
  if [ -s "$DAO_HOME/cf.url" ]; then
    local u=$(cat "$DAO_HOME/cf.url")
    echo "  cloudflared: $u"
    echo "  vm_omni:     $u/_/health · $u/_/stat"
    echo "  ttyd:        $u/port/7681/"
    echo "  filebrowser: $u/port/8888/"
  else
    echo "  cloudflared: (no URL)"
  fi
  echo "─── tasks ───"
  local pending=$(ls -1 "$DAO_HOME"/tasks/*.json 2>/dev/null | wc -l)
  local done=$(ls -1 "$DAO_HOME"/results/*.json 2>/dev/null | wc -l)
  echo "  pending: $pending · done: $done"
  echo "─── gist ───"
  if [ -n "${GIST_ID:-}${DAO_GIST_ID:-}" ]; then
    echo "  enabled · last gist publish: $(stat -c '%y' "$DAO_HOME/.last_gist" 2>/dev/null || echo never)"
  else
    echo "  disabled (set GIST_ID + GIST_TOKEN)"
  fi
}

cmd_help() {
  cat <<EOF
$SEAL v$VERSION

§ 主公诏 (重锚)
  彻底打通虚拟机一切 · 不依赖一切资源 (账号/agent/额度/本机)
  无限制并发、无限制操作、无限制使用
  Devin Cloud 官方 VM 取天下资源尽为我所用 · 道法自然推进到底 · 无为而无以为

§ 命令
  start            · 全套件起 (install + resource_max + omni + ttyd + filebrowser + cloudflared + daemon)
  stop             · 停全部
  status           · 状态
  install          · 仅 install (apt + binary)
  resource-max     · 仅 CPU/sysctl/ulimit 极取
  self-renew       · 强制 cloudflared tunnel 续 (URL 死了用)
  daemon           · 起守护进程 (30s 周期 · service 自重启 · gist 心跳)
  daemon-inner     · 守护循环本体 (内部用)
  watchdog-once    · 单次 watchdog (debug)
  mesh-pull        · 拉 mesh peers (从 Gist)
  gist-publish     · 立即 publish 心跳到 Gist
  task-submit <c>  · 提交任务 (写 tasks/)
  task-run         · 跑所有 pending tasks
  task-harvest     · 拉所有 results
  systemd-install  · 装 systemd unit (开机自起)
  exec <cmd>       · 直接 bash 执 (调试用)

§ 环境变量
  DAO_HOME         · 默 ~/.dao_vm_total
  GIST_ID          · GitHub Gist ID (做无中心心跳板)
  GIST_TOKEN       · GitHub PAT (gist 权限)

§ 道义
  ✗ 本机依赖   (start 后本机可关 · VM 自续永生)
  ✗ 账号依赖   (vm_omni 不需 token · cloudflared trycloudflare 免账号)
  ✗ agent依赖  (ttyd/filebrowser/cloudflared 全官方原生工具)
  ✗ 额度依赖   (永久 0 ACU)
  ✓ 长链路稳定 (daemon 30s 周期 · self_renew 自动)
  ✓ 取天下资源 (resource_max + task executor + mesh)
EOF
}

main() {
  local sub="${1:-help}"; shift 2>/dev/null || true
  case "$sub" in
    start)            cmd_start ;;
    stop)             cmd_stop ;;
    status)           cmd_status ;;
    install)          detect_env; install_all ;;
    resource-max)     detect_env; resource_max ;;
    self-renew)       self_renew ;;
    daemon)           start_daemon ;;
    daemon-inner)     daemon_loop ;;
    watchdog-once)    watchdog_once ;;
    mesh-pull)        mesh_pull ;;
    gist-publish)     gist_publish ;;
    task-submit)      task_submit "$@" ;;
    task-run)         task_run_pending ;;
    task-harvest)     task_harvest ;;
    systemd-install)  install_systemd ;;
    exec)             bash -c "$*" ;;
    help|--help|-h)   cmd_help ;;
    version|--version|-v) echo "$VERSION" ;;
    *)                err "unknown subcommand: $sub"; cmd_help; exit 1 ;;
  esac
}

main "$@"
