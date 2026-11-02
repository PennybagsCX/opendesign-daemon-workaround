<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Template: install.sh replaces __HOME__, __APP__ and __PORT__ with this
     machine's values and writes the result to ~/Library/LaunchAgents/. -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.opendesign-workaround.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>exec "__APP__/Contents/Frameworks/Open Design Helper.app/Contents/MacOS/Open Design Helper" "__APP__/Contents/Resources/app/prebundled/daemon/daemon-cli.mjs" --no-open --host 127.0.0.1 --port __PORT__</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>ELECTRON_RUN_AS_NODE</key>
        <string>1</string>
        <key>PATH</key>
        <string>/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>30</integer>
    <key>StandardOutPath</key>
    <string>__HOME__/Library/Logs/opendesign-daemon-launchd.log</string>
    <key>StandardErrorPath</key>
    <string>__HOME__/Library/Logs/opendesign-daemon-launchd.log</string>
</dict>
</plist>
