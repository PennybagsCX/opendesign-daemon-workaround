#!/usr/bin/env bash
# install.sh — set up the OpenDesign daemon workaround (see README.md)
#
#   ./install.sh                install + start the launchd daemon agent
#   ./install.sh --dry-run      print the plan, touch nothing
#   ./install.sh --disable-broken-agent
#                               ALSO disable the stock desktop LaunchAgent
#                               (ai.open-design.desktop.stable) if it keeps
#                               failing at login. Reversible: see uninstall.sh
#
# The daemon runs headless in ELECTRON_RUN_AS_NODE mode on 127.0.0.1:7456.
# It does NOT start or fix the OpenDesign UI.
set -u

DRY_RUN=0
DISABLE_BROKEN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --disable-broken-agent) DISABLE_BROKEN=1 ;;
    *) echo "unknown flag: $arg"; exit 1 ;;
  esac
done

LABEL="com.opendesign-workaround.daemon"
PORT="${OD_DAEMON_PORT:-7456}"
BASE="$HOME/Library/Application Support/Open Design/launcher/channels/stable/namespaces/release-stable/versions"
AGENT_SRC="$(cd "$(dirname "$0")" && pwd)/com.opendesign-workaround.daemon.plist.tpl"
AGENT_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
SUPERVISOR_SRC="$(cd "$(dirname "$0")" && pwd)/opendesign-supervisor.sh"

latest_app() { ls -d "$BASE"/*/payload/Open\ Design.app 2>/dev/null | sort -V | tail -1; }

APP="$(latest_app)"
[ -n "$APP" ] || { echo "error: no Open Design payload found under $BASE"; exit 1; }
[ -x "$APP/Contents/Frameworks/Open Design Helper.app/Contents/MacOS/Open Design Helper" ] || {
  echo "error: Helper binary missing in the newest payload"; exit 1; }

APP_ESC=$(printf '%s' "$APP" | sed 's/[&/\]/\\&/g')

echo "plan:"
echo "  payload   : $APP"
echo "  agent     : $AGENT_DST (label $LABEL, port $PORT)"
echo "  supervisor: $SUPERVISOR_SRC"
[ "$DISABLE_BROKEN" -eq 1 ] && echo "  also      : disable LaunchAgent ai.open-design.desktop.stable"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run: nothing was written or loaded."
  exit 0
fi

# generate the real plist from the template with this user's home baked in
sed "s|__HOME__|$HOME|g; s|__APP__|$APP_ESC|g; s|__PORT__|$PORT|g" "$AGENT_SRC" > "$AGENT_DST"
chmod 644 "$AGENT_DST"
plutil -lint "$AGENT_DST" >/dev/null || { echo "error: generated plist failed lint"; exit 1; }

mkdir -p "$HOME/Library/Logs"
launchctl unload "$AGENT_DST" 2>/dev/null
launchctl load "$AGENT_DST"

sleep 8
if curl -s --max-time 3 -o /dev/null "http://127.0.0.1:$PORT/"; then
  echo "ok: daemon is listening on 127.0.0.1:$PORT"
else
  echo "warning: daemon did not answer within 8s — check ~/Library/Logs/opendesign-daemon-launchd.log"
fi

if [ "$DISABLE_BROKEN" -eq 1 ]; then
  launchctl disable "gui/$(id -u)/ai.open-design.desktop.stable" 2>/dev/null
  launchctl bootout "gui/$(id -u)/ai.open-design.desktop.stable" 2>/dev/null
  echo "disabled the stock desktop LaunchAgent (re-enable later: see uninstall.sh)"
fi

echo
echo "next: $(dirname "$0")/opendesign-supervisor.sh status"
