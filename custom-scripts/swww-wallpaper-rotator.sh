#!/bin/bash

# SWWW Wallpaper Rotation Script
# Rotates wallpapers randomly on both monitors (same wallpaper on both)
# Supports DP-1 (1920x1080) and DP-2 (1920x1200 portrait)

# Configuration
WALLPAPER_DIR="$HOME/.config/assets/catpuccin-backgrounds"
STATE_FILE="$HOME/.cache/swww_wallpaper_state"
LOG_FILE="$HOME/.cache/swww_wallpaper.log"
ROTATION_INTERVAL=1800  # 30 minutes (in seconds)

# Transition settings
TRANSITION_TYPE="outer"
TRANSITION_DURATION="0.8"
TRANSITION_FPS="255"

# Supported image formats
SUPPORTED_FORMATS=("jpg" "jpeg" "png" "webp" "gif" "bmp")

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_status() {
    case $2 in
        "info") echo -e "${BLUE}[INFO]${NC} $1" ;;
        "success") echo -e "${GREEN}[SUCCESS]${NC} $1" ;;
        "warning") echo -e "${YELLOW}[WARNING]${NC} $1" ;;
        "error") echo -e "${RED}[ERROR]${NC} $1" ;;
        *) echo "$1" ;;
    esac
}

# Function to check if swww daemon is running
check_swww_daemon() {
    if ! pgrep -x "swww-daemon" > /dev/null; then
        print_status "Starting swww daemon..." "info"
        log_message "Starting swww daemon"
        swww-daemon &
        sleep 2
        
        if ! pgrep -x "swww-daemon" > /dev/null; then
            print_status "Failed to start swww daemon" "error"
            log_message "ERROR: Failed to start swww daemon"
            exit 1
        fi
    fi
}

# Function to get list of wallpapers
get_wallpapers() {
    local wallpapers=()
    
    if [ ! -d "$WALLPAPER_DIR" ]; then
        print_status "Wallpaper directory not found: $WALLPAPER_DIR" "error"
        log_message "ERROR: Wallpaper directory not found: $WALLPAPER_DIR"
        exit 1
    fi
    
    # Find all supported image files
    for format in "${SUPPORTED_FORMATS[@]}"; do
        while IFS= read -r -d '' file; do
            wallpapers+=("$file")
        done < <(find "$WALLPAPER_DIR" -type f -iname "*.${format}" -print0 2>/dev/null)
    done
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        print_status "No wallpapers found in $WALLPAPER_DIR" "error"
        log_message "ERROR: No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    printf '%s\n' "${wallpapers[@]}"
}

# Function to get a random wallpaper (avoiding the last one)
get_random_wallpaper() {
    local wallpapers=()
    mapfile -t wallpapers < <(get_wallpapers)
    
    local last_wallpaper=""
    if [ -f "$STATE_FILE" ]; then
        last_wallpaper=$(cat "$STATE_FILE")
    fi
    
    # If we have more than one wallpaper, avoid repeating the last one
    if [ ${#wallpapers[@]} -gt 1 ] && [ -n "$last_wallpaper" ]; then
        local filtered_wallpapers=()
        for wallpaper in "${wallpapers[@]}"; do
            if [ "$wallpaper" != "$last_wallpaper" ]; then
                filtered_wallpapers+=("$wallpaper")
            fi
        done
        wallpapers=("${filtered_wallpapers[@]}")
    fi
    
    # Select random wallpaper
    local random_index=$((RANDOM % ${#wallpapers[@]}))
    echo "${wallpapers[$random_index]}"
}

# Function to set wallpaper on both monitors
set_wallpaper() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        print_status "Wallpaper file not found: $wallpaper" "error"
        log_message "ERROR: Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    print_status "Setting wallpaper: $(basename "$wallpaper")" "info"
    log_message "Setting wallpaper: $wallpaper"
    
    # Set wallpaper on both monitors with the same image
    if swww img "$wallpaper" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS" 2>/dev/null; then
        
        # Save current wallpaper to state file
        echo "$wallpaper" > "$STATE_FILE"
        print_status "Wallpaper set successfully on both monitors" "success"
        log_message "Wallpaper set successfully: $(basename "$wallpaper")"
        return 0
    else
        print_status "Failed to set wallpaper" "error"
        log_message "ERROR: Failed to set wallpaper: $wallpaper"
        return 1
    fi
}

# Function to restore last wallpaper
restore_wallpaper() {
    if [ -f "$STATE_FILE" ]; then
        local last_wallpaper=$(cat "$STATE_FILE")
        if [ -f "$last_wallpaper" ]; then
            print_status "Restoring last wallpaper: $(basename "$last_wallpaper")" "info"
            set_wallpaper "$last_wallpaper"
            return 0
        fi
    fi
    
    # If no valid saved wallpaper, set a random one
    print_status "No valid saved wallpaper, selecting random..." "info"
    local random_wallpaper=$(get_random_wallpaper)
    set_wallpaper "$random_wallpaper"
}

# Function to start rotation daemon
start_rotation_daemon() {
    print_status "Starting wallpaper rotation daemon (interval: ${ROTATION_INTERVAL}s)" "info"
    log_message "Starting wallpaper rotation daemon"
    
    while true; do
        sleep "$ROTATION_INTERVAL"
        
        # Check if swww daemon is still running
        if ! pgrep -x "swww-daemon" > /dev/null; then
            print_status "swww daemon stopped, restarting..." "warning"
            log_message "WARNING: swww daemon stopped, restarting"
            check_swww_daemon
        fi
        
        # Set new random wallpaper
        local new_wallpaper=$(get_random_wallpaper)
        set_wallpaper "$new_wallpaper"
    done
}

# Function to show usage
show_usage() {
    echo "SWWW Wallpaper Rotator"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --daemon       Run as daemon (continuous rotation)"
    echo "  -o, --once         Set random wallpaper once and exit"
    echo "  -r, --restore      Restore last wallpaper"
    echo "  -l, --list         List available wallpapers"
    echo "  -s, --status       Show current status"
    echo "  -k, --kill         Kill running daemon"
    echo "  -h, --help         Show this help"
    echo ""
    echo "Configuration:"
    echo "  Wallpaper directory: $WALLPAPER_DIR"
    echo "  Rotation interval: ${ROTATION_INTERVAL} seconds"
    echo "  State file: $STATE_FILE"
    echo "  Log file: $LOG_FILE"
}

# Function to kill daemon
kill_daemon() {
    local pid_file="$HOME/.cache/swww_wallpaper_daemon.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$pid_file"
            print_status "Daemon killed (PID: $pid)" "success"
            log_message "Daemon killed (PID: $pid)"
        else
            rm -f "$pid_file"
            print_status "Daemon was not running" "info"
        fi
    else
        print_status "No daemon PID file found" "info"
    fi
}

# Function to show status
show_status() {
    print_status "SWWW Wallpaper Rotator Status" "info"
    echo ""
    
    # Check swww daemon
    if pgrep -x "swww-daemon" > /dev/null; then
        print_status "swww daemon: Running" "success"
    else
        print_status "swww daemon: Not running" "warning"
    fi
    
    # Check rotation daemon
    local pid_file="$HOME/.cache/swww_wallpaper_daemon.pid"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Rotation daemon: Running (PID: $pid)" "success"
        else
            print_status "Rotation daemon: Not running (stale PID file)" "warning"
        fi
    else
        print_status "Rotation daemon: Not running" "warning"
    fi
    
    # Show current wallpaper
    if [ -f "$STATE_FILE" ]; then
        local current=$(cat "$STATE_FILE")
        print_status "Current wallpaper: $(basename "$current")" "info"
    else
        print_status "Current wallpaper: Unknown" "info"
    fi
    
    # Show wallpaper count
    local count=$(get_wallpapers | wc -l)
    print_status "Available wallpapers: $count" "info"
    
    # Show next rotation time
    if [ -f "$pid_file" ]; then
        print_status "Next rotation: ~$((ROTATION_INTERVAL / 60)) minutes" "info"
    fi
}

# Create cache directory if it doesn't exist
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Parse command line arguments
case "${1}" in
    -d|--daemon)
        check_swww_daemon
        
        # Save daemon PID
        echo $$ > "$HOME/.cache/swww_wallpaper_daemon.pid"
        
        # Set initial wallpaper
        restore_wallpaper
        
        # Start rotation daemon
        start_rotation_daemon
        ;;
    -o|--once)
        check_swww_daemon
        new_wallpaper=$(get_random_wallpaper)
        set_wallpaper "$new_wallpaper"
        ;;
    -r|--restore)
        check_swww_daemon
        restore_wallpaper
        ;;
    -l|--list)
        echo "Available wallpapers in $WALLPAPER_DIR:"
        get_wallpapers | while read -r wallpaper; do
            echo "  $(basename "$wallpaper")"
        done
        ;;
    -s|--status)
        show_status
        ;;
    -k|--kill)
        kill_daemon
        ;;
    -h|--help|"")
        show_usage
        ;;
    *)
        print_status "Unknown option: $1" "error"
        show_usage
        exit 1
        ;;
esac
