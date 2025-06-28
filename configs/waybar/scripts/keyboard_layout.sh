#!/bin/bash

# Script for Waybar custom module to show keyboard language
# Save as ~/scripts/waybar_keyboard.sh

# Debug: Check if hyprctl works
if ! command -v hyprctl &> /dev/null; then
    echo "[L] ERROR"
    exit 1
fi

# Get current keyboard layout from Hyprland
current_layout=$(hyprctl devices -j | jq -r '.keyboards[0].active_keymap' 2>/dev/null)

# Debug: If jq fails, try without jq
if [ -z "$current_layout" ] || [ "$current_layout" = "null" ]; then
    # Alternative method without jq
    current_layout=$(hyprctl devices | grep -A5 "Keyboard" | grep "keymap" | head -1 | awk '{print $2}')
fi

# Debug: If still empty, show raw output
if [ -z "$current_layout" ]; then
    echo "[L] UNKNOWN"
    exit 1
fi

# Format: [L] {language}
case $current_layout in
    "English (US)"|"us") echo "[L] US" ;;
    "Hungarian"|"hu") echo "[L] HU" ;;
    *) echo "[L] $current_layout" ;;
esac