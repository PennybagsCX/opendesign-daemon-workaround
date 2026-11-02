#!/usr/bin/env bash
# opendesign-supervisor.sh — control the standalone OpenDesign daemon sidecar
# that this workaround runs in ELECTRON_RUN_AS_NODE mode on a fixed port.
#
# Why: the packaged OpenDesign app can fail to start in GUI contexts
# (see nexu-io/open-design #8812 / #9261) while its Node daemon works fine.
# This keeps the daemon alive so MCP/CLI clients keep working.
#
# Usage: opendesign-supervisor.sh {start|stop|status|restart}
# Env overrides: OD_DAEMON_PORT (default 7456)
set -u

PORT="${OD_DAEMON_PORT:-7456}"
BASE="$HOME/Library/Application Support/Open Design/launcher/channels/stable/namespaces/release-stable/versions"
LOG="${OD_DAEMON_LOG:-$HOME/Library/Logs/opendesign-daemon.log}"

# resolve the newest installed payload (same layout the official launcher uses)
latest_app() {
  ls -d "$BASE"/*/payload/Open\ Design.app 2>/dev/null | sort -V | tail -1
}

HELPER="$(latest_app)/Contents/Frameworks/Open Design Helper.app/Contents/MacOS/Open Design Helper"
CLI="$(latest_app)/Contents/Resources/app/prebundled/daemon/daemon-cli.mjs"

alive()     { curl -s --max-time 2 -o /dev/null "http://127.0.0.1:$PORT/"; }
daemon_pids() { lsof -nP -iTCP:$PORT -sTCP:LISTEN -t 2>/dev/null | sort -u; }

start() {
  if alive; then
    echo "daemon already alive on 127.0.0.1:$PORT (pids: $(daemon_pids | tr '\n' ' '))"
    return 0
  fi
  [ -x "$HELPER" ] || { echo "error: Helper binary not found under $BASE"; exit 1; }
  [ -f "$CLI" ]    || { echo "error: daemon-cli.mjs not found under $BASE"; exit 1; }
  nohup env ELECTRON_RUN_AS_NODE=1 "$HELPER" "$CLI" \
    --no-open --host 127.0.0.1 --port "$PORT" >> "$LOG" 2>&1 &
  local pid=$!
  local i
  for i in $(seq 1 20); do
    if alive; then
      echo "daemon up: pid $pid on 127.0.0.1:$PORT (log: $LOG)"
      return 0
    fi
    sleep 1
  done
  echo "error: daemon not ready after 20s — check $LOG"
  exit 1
}

stop() {
  local pids
  pids=$(daemon_pids)
  if [ -z "$pids" ]; then
    echo "no daemon listening on $PORT"
  else
    echo "$pids" | xargs kill 2>/dev/null
    echo "stopped daemon pids: $(echo "$pids" | tr '\n' ' ')"
  fi
}

status() {
  if alive; then
    echo "alive on 127.0.0.1:$PORT (pids: $(daemon_pids | tr '\n' ' '))"
  else
    echo "down"
    exit 1
  fi
}

case "${1:-status}" in
  start)   start ;;
  stop)    stop ;;
  status)  status ;;
  restart) stop; sleep 1; start ;;
  *) echo "usage: $0 {start|stop|status|restart}"; exit 1 ;;
esac
