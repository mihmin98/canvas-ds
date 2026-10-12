#!/bin/bash

THEME_PATH=""
if [ -d "/roms/themes/canvas-ds" ]; then
    THEME_PATH="/roms/themes/canvas-ds"
elif [ -d "/roms/themes/canvas-ds-main" ]; then
    THEME_PATH="/roms/themes/canvas-ds-main"
elif [ -d "/storage/.config/emulationstation/themes/canvas-ds" ]; then
    THEME_PATH="/storage/.config/emulationstation/themes/canvas-ds"
elif [ -d "/storage/.config/emulationstation/themes/canvas-ds-main" ]; then
    THEME_PATH="/storage/.config/emulationstation/themes/canvas-ds-main"
else
    echo "ERROR! Couldn't find a canvas-ds theme folder on your device!"
    exit 1
fi

LAUNCHER_SCRIPT="${THEME_PATH}/scripts/start_es_rgdsplus.sh"

if [ ! -f "$LAUNCHER_SCRIPT" ]; then
    echo "ERROR! Could not find the launcher script at $LAUNCHER_SCRIPT"
    exit 1
fi

# Bind the theme's launcher to override the default system window initialization
chmod +x "$LAUNCHER_SCRIPT"
mount --bind "$LAUNCHER_SCRIPT" "/usr/bin/start_es.sh"

cat <<EOF >/storage/.config/sway/config
seat * hide_cursor 1000
default_border none
exec_always mako

# Outputs
output DSI-2 transform 0
output DSI-2 position 0 0
output DSI-2 bg #000000 solid_color
output DSI-2 allow_tearing yes
output DSI-2 max_render_time off
output DSI-1 position 1024 0
output DSI-1 bg #000000 solid_color

# Window rules
for_window [title=".*(Secondary|\[w2\]|Sub|Bottom|Screen 2|GamePad).*"] move window to output DSI-1
for_window [title="RetroArch.*"] exec /usr/bin/vertical-check

# Lowerdeck rules
for_window [app_id="lowerdeck"] floating enable, fullscreen enable, move window to output DSI-1
no_focus [app_id="lowerdeck"]

# EmulationStation controls attach on seat 0
exec_always swaymsg '[app_id="emulationstation"]' seat seat0 attach "0:0:wlr_virtual_keyboard_v1"

# Make sure top screen is on
for_window [title=".*(Secondary|\[w2\]|Sub|Bottom|Screen 2|GamePad).*"] output DSI-1 power on

#Drastic Specific rules
for_window [app_id="drastic"] input "1046:911:Goodix_Capacitive_TouchScreen" map_to_output DSI-2

# EmulationStation rules
for_window [app_id="emulationstation"] reload
exec_always swaymsg '[app_id="emulationstation"]' floating enable, fullscreen disable, move absolute position 0 0
exec_always swaymsg '[app_id="emulationstation"]' focus

# EmulationStation Attach touch input on seat 1
exec_always swaymsg '[app_id="emulationstation"]' seat seat1 attach "1046:911:Goodix_Capacitive_TouchScreen"
EOF

swaymsg reload

ES_SETTINGS="/storage/.config/emulationstation/es_settings.cfg"
if grep -q '<string name="FullScreenMenu"' "$ES_SETTINGS" 2>/dev/null; then
    sed -i 's|<string name="FullScreenMenu" value="[^"]*" />|<string name="FullScreenMenu" value="false" />|' "$ES_SETTINGS"
else
    sed -i 's|</config>|\t<string name="FullScreenMenu" value="false" />\n</config>|' "$ES_SETTINGS"
fi

if grep -q '<string name="GameTransitionStyle"' "$ES_SETTINGS" 2>/dev/null; then
    sed -i 's|<string name="GameTransitionStyle" value="[^"]*" />|<string name="GameTransitionStyle" value="fade" />|' "$ES_SETTINGS"
else
    sed -i 's|</config>|\t<string name="GameTransitionStyle" value="fade" />\n</config>|' "$ES_SETTINGS"
fi

if [ ! -f "/tmp/has-restarted-for-theme" ]; then
    touch /tmp/has-restarted-for-theme
    systemctl restart essway
fi
