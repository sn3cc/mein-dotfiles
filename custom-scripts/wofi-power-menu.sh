#!/bin/bash

# Wofi Power Menu Script

# Define options
options="Idle\nSleep\nRestart\nShutdown"

# Show wofi menu and get selection
chosen=$(echo -e "$options" | wofi --show dmenu --prompt "Power Menu" --width 300 --height 150 --style ~/.config/wofi/power-menu.css --hide-search)

# Execute based on selection
case $chosen in
    "Idle")
        # Start a temporary swayidle for instant idle (don't kill existing ones)
        swayidle -w \
            timeout 1 'hyprctl dispatch dpms off' \
            resume 'hyprctl dispatch dpms on && pkill -f "timeout 1.*hyprctl dispatch dpms"' &
        ;;
    "Sleep")
        systemctl suspend
        ;;
    "Restart")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    *)
        # Do nothing if cancelled or invalid selection
        ;;
esac