#!/usr/bin/env bash
# uninstall.sh — remove the OpenDesign daemon workaround
#
#   ./uninstall.sh                 unload + delete the launchd agent
#   ./uninstall.sh --reenable-stock-agent
#                                  also re-enable the stock desktop LaunchAgent
set -u

LABEL="com.opendesign-workaround.daemon"
AGENT_DST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl unload "$AGENT_DST" 2>/dev/null
rm -f "$AGENT_DST"
echo "removed $AGENT_DST (daemon stopped)"

if [ "${1:-}" = "--reenable-stock-agent" ]; then
  launchctl enable "gui/$(id -u)/ai.open-design.desktop.stable" 2>/dev/null
  PLIST="$HOME/Library/LaunchAgents/ai.open-design.desktop.stable.plist"
  [ -f "$PLIST" ] && launchctl load "$PLIST"
  echo "re-enabled the stock desktop LaunchAgent"
fi
