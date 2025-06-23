#!/bin/bash

if [ "$1" = "toggle" ]; then
    hyprctl switchxkblayout evision-endorfy-thock-tkl-keyboard next
else
    layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -1)
    case "$layout" in
        "Hungarian") echo "󰌌 HU" ;;
        "English (US)") echo "󰌌 US" ;;
        *) echo "⌨ $layout" ;;
    esac
fi