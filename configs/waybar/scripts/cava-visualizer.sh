#!/bin/bash

# Kill any existing cava instances for waybar
pkill -f "cava.*waybar"

# Create a temporary cava config for waybar
cat > /tmp/cava_waybar_config << EOF
[general]
bars = 8
bar_width = 1
bar_spacing = 0

[output]
method = raw
raw_target = /tmp/cava_fifo
data_format = ascii
ascii_max_range = 7

[smoothing]
noise_reduction = 77

[eq]
1 = 2
2 = 2
3 = 1
4 = 1
5 = 0
6 = 0
7 = 0
8 = 0
EOF

# Create fifo if it doesn't exist
[ ! -p /tmp/cava_fifo ] && mkfifo /tmp/cava_fifo

# Start cava in background
cava -p /tmp/cava_waybar_config &

# Read from fifo and convert to bar characters
while read -r line < /tmp/cava_fifo; do
    # Convert cava output to visual bars
    output=""
    for char in $line; do
        case $char in
            0) output+=" " ;;
            1) output+="▁" ;;
            2) output+="▂" ;;
            3) output+="▃" ;;
            4) output+="▄" ;;
            5) output+="▅" ;;
            6) output+="▆" ;;
            7) output+="▇" ;;
            *) output+="▁" ;;
        esac
    done
    echo "$output"
done