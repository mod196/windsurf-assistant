#!/usr/bin/env bash
# vm_bootstrap.sh · DevOps bootstrap for CI/CD worker VM
# ----------------------------------------------------------------------
# Sets up an HTTP REST control plane on the VM:
#   - port 8080: lightweight node management server (run/file/spawn/health)
#   - cloudflared tunnel: assigns a *.trycloudflare.com URL for remote access
#   - watchdog: 30s service health loop
#
# Idempotent. No external account or token needed (cloudflared "quick tunnel").
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/zhouyoukang/windsurf-assistant/main/scripts/dao/vm_bootstrap.sh | bash -s -- start
#   bash vm_bootstrap.sh status
#   bash vm_bootstrap.sh self-renew
#
set -u
umask 022

VERSION="1.0.0"
DAO_HOME="${DAO_HOME:-$HOME/.vm_bootstrap}"
LOG="$DAO_HOME/bootstrap.log"
PIDDIR="$DAO_HOME/pid"
mkdir -p "$DAO_HOME" "$PIDDIR" 2>/dev/null

ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG" >&2; }
err() { echo "[$(ts)][ERR] $*" | tee -a "$LOG" >&2; }
ok()  { echo "[$(ts)][OK ] $*" | tee -a "$LOG" >&2; }

# ── detect ─────────────────────────────────────────────────────────────
detect_env() {
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64;; aarch64) ARCH=arm64;; esac
  log "env: arch=$ARCH host=$(hostname) node=$(command -v node || echo none)"
}

# ── install cloudflared (idempotent) ───────────────────────────────────
install_cloudflared() {
  command -v cloudflared >/dev/null 2>&1 && return 0
  log "install: cloudflared ($ARCH)"
  local url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
  sudo curl -fsSL "$url" -o /usr/local/bin/cloudflared 2>/dev/null \
    || curl -fsSL "$url" -o "$DAO_HOME/cloudflared" 2>/dev/null
  if [ -f "$DAO_HOME/cloudflared" ]; then
    chmod +x "$DAO_HOME/cloudflared"
    export PATH="$DAO_HOME:$PATH"
  fi
  sudo chmod +x /usr/local/bin/cloudflared 2>/dev/null || true
  command -v cloudflared >/dev/null 2>&1
}

# ── write management server (port 8080) ───────────────────────────────
write_mgmt_server() {
  cat > "$DAO_HOME/mgmt_server.js" <<'JS_EOF'
"use strict";
// VM management HTTP server · REST primitives
const http = require('http'); const net = require('net');
const fs = require('fs'); const path = require('path');
const { spawn } = require('child_process');

const PORT = parseInt(process.env.MGMT_PORT || '8080', 10);
const START = Date.now();
const TASKS = new Map();

function rid() { return Math.random().toString(36).slice(2,10); }
function send(res, code, ct, body) {
  res.writeHead(code, { 'Content-Type': ct, 'Access-Control-Allow-Origin': '*' });
  res.end(body);
}
function readBody(req) {
  return new Promise((r) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => r(Buffer.concat(chunks)));
    req.on('error', () => r(Buffer.alloc(0)));
  });
}

const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x'); const p = u.pathname;
  try {
    if (p === '/_/health') {
      return send(res, 200, 'application/json', JSON.stringify({
        ok: true, uptime: Math.floor((Date.now()-START)/1000),
        pid: process.pid, node: process.version,
      }));
    }
    if (p === '/_/stat') {
      const stat = {
        uptime: Math.floor((Date.now()-START)/1000), pid: process.pid,
        mem: process.memoryUsage(), cpus: require('os').cpus().length,
        load: require('os').loadavg(), free: require('os').freemem(), total: require('os').totalmem(),
        hostname: require('os').hostname(), platform: process.platform, arch: process.arch,
      };
      return send(res, 200, 'application/json', JSON.stringify(stat));
    }
    if (p === '/_/run' && req.method === 'POST') {
      const body = (await readBody(req)).toString('utf8');
      let cmd = ''; let timeout = 60000; let cwd = process.env.HOME;
      try { const j = JSON.parse(body); cmd = j.cmd || body; if (j.timeout) timeout = j.timeout; if (j.cwd) cwd = j.cwd; } catch { cmd = body; }
      if (!cmd) return send(res, 400, 'text/plain', 'no cmd');
      const id = rid();
      const child = spawn('bash', ['-lc', cmd], { stdio: ['ignore','pipe','pipe'], cwd });
      let stdout=''; let stderr='';
      child.stdout.on('data', d => stdout += d.toString());
      child.stderr.on('data', d => stderr += d.toString());
      const r = await new Promise(rr => {
        let done=false;
        child.on('exit', code => { if(done)return; done=true; rr({ ok: code===0, code, stdout, stderr }); });
        setTimeout(() => { if(done)return; done=true; try{child.kill();}catch{} rr({ ok:false, code:-1, stdout, stderr, timeout:true }); }, timeout);
      });
      return send(res, 200, 'application/json', JSON.stringify({ id, ...r }));
    }
    if (p.startsWith('/_/file/')) {
      const fp = '/' + decodeURIComponent(p.slice('/_/file/'.length));
      if (req.method === 'GET') {
        if (!fs.existsSync(fp)) return send(res, 404, 'text/plain', 'not found');
        return send(res, 200, 'application/octet-stream', fs.readFileSync(fp));
      } else if (req.method === 'PUT') {
        const buf = await readBody(req);
        try {
          fs.mkdirSync(path.dirname(fp), { recursive: true });
          fs.writeFileSync(fp, buf);
          return send(res, 200, 'application/json', JSON.stringify({ ok:true, bytes: buf.length, path: fp }));
        } catch(e) {
          return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message }));
        }
      } else if (req.method === 'DELETE') {
        try { fs.unlinkSync(fp); return send(res, 200, 'application/json', JSON.stringify({ ok:true })); }
        catch(e) { return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message })); }
      }
    }
    if (p === '/_/spawn' && req.method === 'POST') {
      const body = (await readBody(req)).toString('utf8');
      let cmd = ''; let env = {}; let cwd = process.env.HOME;
      try { const j = JSON.parse(body); cmd = j.cmd || body; env = j.env || {}; cwd = j.cwd || cwd; } catch { cmd = body; }
      if (!cmd) return send(res, 400, 'text/plain', 'no cmd');
      const id = rid();
      const child = spawn('bash', ['-lc', cmd], {
        stdio: ['ignore','pipe','pipe'], detached: true, cwd,
        env: { ...process.env, ...env },
      });
      const task = { id, cmd, pid: child.pid, started: Date.now(), stdout: '', stderr: '', exitCode: null };
      TASKS.set(id, task);
      child.stdout.on('data', d => { task.stdout += d.toString(); if (task.stdout.length > 65536) task.stdout = task.stdout.slice(-65536); });
      child.stderr.on('data', d => { task.stderr += d.toString(); if (task.stderr.length > 65536) task.stderr = task.stderr.slice(-65536); });
      child.on('exit', code => { task.exitCode = code; task.finished = Date.now(); });
      child.unref();
      return send(res, 200, 'application/json', JSON.stringify({ ok:true, id, pid: child.pid }));
    }
    if (p.startsWith('/_/task/')) {
      const id = p.slice('/_/task/'.length);
      const t = TASKS.get(id);
      if (!t) return send(res, 404, 'text/plain', 'no such task');
      return send(res, 200, 'application/json', JSON.stringify(t));
    }
    if (p === '/_/tasks') {
      return send(res, 200, 'application/json', JSON.stringify([...TASKS.values()]));
    }
    if (p === '/_/kill' && req.method === 'POST') {
      const body = (await readBody(req)).toString('utf8');
      try {
        const j = JSON.parse(body);
        if (j.pid) { try { process.kill(j.pid); } catch {} return send(res, 200, 'application/json', JSON.stringify({ ok:true, pid: j.pid })); }
        if (j.id) { const t = TASKS.get(j.id); if (t?.pid) { try { process.kill(t.pid); } catch {} return send(res, 200, 'application/json', JSON.stringify({ ok:true, killed: t.pid })); } }
        return send(res, 400, 'text/plain', 'need pid or id');
      } catch (e) { return send(res, 400, 'text/plain', e.message); }
    }
    if (p.startsWith('/port/')) {
      // proxy to local port: /port/<N>/path → 127.0.0.1:N/path
      const m = p.match(/^\/port\/(\d+)(\/.*)?$/);
      if (!m) return send(res, 400, 'text/plain', 'bad port');
      const tgt = parseInt(m[1]); const subPath = (m[2] || '/') + (u.search || '');
      const opts = { hostname: '127.0.0.1', port: tgt, path: subPath, method: req.method,
        headers: { ...req.headers, host: `127.0.0.1:${tgt}` } };
      const proxyReq = http.request(opts, (pr) => {
        res.writeHead(pr.statusCode, pr.headers);
        pr.pipe(res);
      });
      proxyReq.on('error', e => { try { send(res, 502, 'text/plain', 'bad gateway: ' + e.message); } catch {} });
      req.pipe(proxyReq);
      return;
    }
    // landing
    return send(res, 200, 'text/html',
      `<h1>VM mgmt server</h1>
       <p>uptime=${Math.floor((Date.now()-START)/1000)}s · pid=${process.pid} · node=${process.version}</p>
       <ul>
         <li>GET  /_/health</li><li>GET  /_/stat</li>
         <li>POST /_/run {cmd, timeout?, cwd?}</li>
         <li>GET/PUT/DELETE /_/file/&lt;path&gt;</li>
         <li>POST /_/spawn {cmd, env?, cwd?}</li>
         <li>GET  /_/task/&lt;id&gt;</li><li>GET /_/tasks</li>
         <li>POST /_/kill {pid|id}</li>
         <li>/port/&lt;N&gt;/...  ← reverse proxy to local port</li>
       </ul>`);
  } catch (e) {
    return send(res, 500, 'application/json', JSON.stringify({ ok:false, err: e.message }));
  }
});

// WebSocket upgrade proxy (for /port/N/)
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

server.listen(PORT, '0.0.0.0', () => {
  console.log(`mgmt_server :${PORT} pid=${process.pid}`);
});
JS_EOF
}

start_mgmt() {
  local pidf="$PIDDIR/mgmt.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
    ok "mgmt :8080 alive pid=$(cat "$pidf")"
    return 0
  fi
  command -v node >/dev/null || { err "node not found"; return 1; }
  write_mgmt_server
  MGMT_PORT=8080 nohup node "$DAO_HOME/mgmt_server.js" >> "$LOG" 2>&1 &
  echo $! > "$pidf"
  sleep 1
  if curl -fsS -m 3 "http://127.0.0.1:8080/_/health" >/dev/null 2>&1; then
    ok "mgmt :8080 started pid=$(cat "$pidf")"
  else
    err "mgmt failed to start"; return 1
  fi
}

start_cf() {
  local pidf="$PIDDIR/cf.pid"
  local urlf="$DAO_HOME/cf.url"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null && [ -s "$urlf" ]; then
    ok "cloudflared alive · $(cat "$urlf")"
    return 0
  fi
  command -v cloudflared >/dev/null || { err "no cloudflared"; return 1; }
  rm -f "$urlf"
  nohup cloudflared tunnel --url http://127.0.0.1:8080 --no-autoupdate >> "$DAO_HOME/cf.log" 2>&1 &
  echo $! > "$pidf"
  log "waiting cloudflared URL ..."
  local i=0
  while [ $i -lt 60 ]; do
    local u=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$DAO_HOME/cf.log" 2>/dev/null | head -1)
    if [ -n "$u" ]; then
      echo "$u" > "$urlf"
      ok "cloudflared URL: $u"
      return 0
    fi
    sleep 1; i=$((i+1))
  done
  err "cloudflared timeout"
  tail -20 "$DAO_HOME/cf.log" 1>&2
  return 1
}

self_renew() {
  log "self_renew: kill + restart cloudflared"
  local pidf="$PIDDIR/cf.pid"
  [ -f "$pidf" ] && kill "$(cat "$pidf")" 2>/dev/null; sleep 2
  rm -f "$pidf" "$DAO_HOME/cf.log" "$DAO_HOME/cf.url"
  start_cf
}

watchdog_once() {
  # mgmt alive?
  local pidf="$PIDDIR/mgmt.pid"
  if [ ! -f "$pidf" ] || ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: mgmt dead · restart"; start_mgmt
  fi
  # cf alive?
  pidf="$PIDDIR/cf.pid"
  if [ ! -f "$pidf" ] || ! kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
    log "watchdog: cf dead · self_renew"; self_renew
  else
    local u=$(cat "$DAO_HOME/cf.url" 2>/dev/null || echo "")
    if [ -n "$u" ]; then
      local rc=$(curl -fsS -m 10 -o /dev/null -w "%{http_code}" "$u/_/health" 2>/dev/null || echo "0")
      [ "$rc" != "200" ] && { log "watchdog: tunnel unhealthy ($rc) · self_renew"; self_renew; }
    fi
  fi
}

daemon_loop() {
  log "daemon_loop: interval=30s"
  while true; do watchdog_once || true; sleep 30; done
}

start_daemon() {
  local pidf="$PIDDIR/daemon.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then ok "daemon alive"; return 0; fi
  nohup bash "$0" daemon-inner >> "$LOG" 2>&1 &
  echo $! > "$pidf"
  ok "daemon started pid=$(cat "$pidf")"
}

cmd_start() {
  detect_env
  install_cloudflared || err "cloudflared install failed"
  start_mgmt
  start_cf
  start_daemon
  cmd_status
}

cmd_stop() {
  for s in daemon cf mgmt; do
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
  echo "════ vm_bootstrap v$VERSION ════"
  echo "host: $(hostname) · arch: $ARCH"
  echo "DAO_HOME: $DAO_HOME"
  echo "─ services ─"
  for s in mgmt cf daemon; do
    local pidf="$PIDDIR/$s.pid"
    if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
      printf "  %-10s ALIVE pid=%s\n" "$s" "$(cat "$pidf")"
    else
      printf "  %-10s DEAD\n" "$s"
    fi
  done
  echo "─ URL ─"
  if [ -s "$DAO_HOME/cf.url" ]; then
    local u=$(cat "$DAO_HOME/cf.url")
    echo "  $u"
    echo "  health: $u/_/health"
    echo "  port-N: $u/port/<N>/..."
  else
    echo "  (no URL)"
  fi
}

cmd_help() {
  cat <<EOF
vm_bootstrap v$VERSION · DevOps bootstrap for CI/CD worker VM

USAGE:
  bash $0 start         · install + start mgmt:8080 + cloudflared + watchdog
  bash $0 stop          · stop all
  bash $0 status        · show status + URL
  bash $0 self-renew    · force cloudflared tunnel rotation
  bash $0 daemon        · start watchdog daemon
  bash $0 daemon-inner  · watchdog loop body (internal)
EOF
}

main() {
  local sub="${1:-help}"; shift 2>/dev/null || true
  case "$sub" in
    start)           cmd_start ;;
    stop)            cmd_stop ;;
    status)          cmd_status ;;
    self-renew)      self_renew ;;
    daemon)          start_daemon ;;
    daemon-inner)    daemon_loop ;;
    watchdog-once)   watchdog_once ;;
    help|--help|-h)  cmd_help ;;
    version|--version|-v) echo "$VERSION" ;;
    *)               err "unknown: $sub"; cmd_help; exit 1 ;;
  esac
}

main "$@"
