#!/bin/bash

# EndeavourOS Automatic Update Checker and Backup Script
# Author: System Administrator
# Version: 1.0

# Configuration
BACKUP_DIR="/backup/endeavouros"
LOG_FILE="$HOME/.local/share/endeavouros-maintenance.log"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="endeavouros_backup_$DATE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check for updates
check_updates() {
    print_status "Checking for system updates..." "info"
    log_message "Starting update check"
    
    # Update package databases
    sudo pacman -Sy > /dev/null 2>&1
    
    # Check for official repo updates
    OFFICIAL_UPDATES=$(pacman -Qu | grep -v "\[installed: " | wc -l)
    
    # Check for AUR updates (if yay is installed)
    AUR_UPDATES=0
    if command -v yay &> /dev/null; then
        AUR_UPDATES=$(yay -Qua 2>/dev/null | wc -l)
    fi
    
    TOTAL_UPDATES=$((OFFICIAL_UPDATES + AUR_UPDATES))
    
    if [ $TOTAL_UPDATES -gt 0 ]; then
        print_status "Found $TOTAL_UPDATES updates available:" "warning"
        if [ $OFFICIAL_UPDATES -gt 0 ]; then
            print_status "  - Official repositories: $OFFICIAL_UPDATES packages" "info"
            log_message "Official updates available: $OFFICIAL_UPDATES"
        fi
        if [ $AUR_UPDATES -gt 0 ]; then
            print_status "  - AUR packages: $AUR_UPDATES packages" "info"
            log_message "AUR updates available: $AUR_UPDATES"
        fi
        
        # Show available updates
        echo -e "\n${BLUE}Available updates:${NC}"
        pacman -Qu | head -20
        if [ $OFFICIAL_UPDATES -gt 20 ]; then
            echo "... and $(($OFFICIAL_UPDATES - 20)) more packages"
        fi
        
        return 1
    else
        print_status "System is up to date!" "success"
        log_message "No updates available"
        return 0
    fi
}

# Function to create system backup
create_backup() {
    print_status "Starting system backup..." "info"
    log_message "Starting backup creation"
    
    # Create backup directory if it doesn't exist
    sudo mkdir -p "$BACKUP_DIR"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_status "Failed to create backup directory: $BACKUP_DIR" "error"
        log_message "ERROR: Failed to create backup directory"
        return 1
    fi
    
    FULL_BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    sudo mkdir -p "$FULL_BACKUP_PATH"
    
    print_status "Backing up system configuration..." "info"
    
    # Backup package lists
    print_status "  - Creating package lists..." "info"
    pacman -Qqe > "$FULL_BACKUP_PATH/explicitly_installed_packages.txt"
    pacman -Qqm > "$FULL_BACKUP_PATH/aur_packages.txt" 2>/dev/null || touch "$FULL_BACKUP_PATH/aur_packages.txt"
    
    # Backup important system files
    print_status "  - Backing up system configuration files..." "info"
    sudo cp -r /etc "$FULL_BACKUP_PATH/" 2>/dev/null || print_status "    Warning: Some /etc files couldn't be copied" "warning"
    
    # Backup user home directory (excluding large directories)
    print_status "  - Backing up user configuration..." "info"
    rsync -av --exclude='.cache' --exclude='.local/share/Trash' \
          --exclude='Downloads' --exclude='Videos' --exclude='Music' \
          --exclude='.steam' --exclude='Games' \
          "$HOME/" "$FULL_BACKUP_PATH/home/" 2>/dev/null || true
    
    # Backup bootloader configuration
    if [ -d /boot/loader ]; then
        print_status "  - Backing up systemd-boot configuration..." "info"
        sudo cp -r /boot/loader "$FULL_BACKUP_PATH/" 2>/dev/null || true
    fi
    
    if [ -d /boot/grub ]; then
        print_status "  - Backing up GRUB configuration..." "info"
        sudo cp -r /boot/grub "$FULL_BACKUP_PATH/" 2>/dev/null || true
    fi
    
    # Create system info file
    print_status "  - Generating system information..." "info"
    {
        echo "Backup created: $(date)"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Uptime: $(uptime)"
        echo ""
        echo "Disk usage:"
        df -h
        echo ""
        echo "Memory info:"
        free -h
    } > "$FULL_BACKUP_PATH/system_info.txt"
    
    # Set proper permissions
    sudo chown -R root:root "$FULL_BACKUP_PATH"
    sudo chmod -R 755 "$FULL_BACKUP_PATH"
    
    print_status "Backup completed: $FULL_BACKUP_PATH" "success"
    log_message "Backup completed successfully: $FULL_BACKUP_PATH"
    
    # Clean up old backups (keep last 5)
    cleanup_old_backups
}

# Function to clean up old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups..." "info"
    
    if [ -d "$BACKUP_DIR" ]; then
        BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" | grep "endeavouros_backup_" | wc -l)
        if [ $BACKUP_COUNT -gt 5 ]; then
            EXCESS_BACKUPS=$((BACKUP_COUNT - 5))
            print_status "Removing $EXCESS_BACKUPS old backup(s)..." "info"
            ls -1t "$BACKUP_DIR" | grep "endeavouros_backup_" | tail -n $EXCESS_BACKUPS | while read backup; do
                sudo rm -rf "$BACKUP_DIR/$backup"
                print_status "  Removed: $backup" "info"
                log_message "Removed old backup: $backup"
            done
        fi
    fi
}

# Function to install updates
install_updates() {
    print_status "Installing updates..." "info"
    log_message "Starting update installation"
    
    # Update official packages
    if ! sudo pacman -Syu --noconfirm; then
        print_status "Failed to install official updates" "error"
        log_message "ERROR: Failed to install official updates"
        return 1
    fi
    
    # Update AUR packages if yay is available
    if command -v yay &> /dev/null; then
        if ! yay -Syu --noconfirm; then
            print_status "Failed to install AUR updates" "error"
            log_message "ERROR: Failed to install AUR updates"
            return 1
        fi
    fi
    
    print_status "Updates installed successfully!" "success"
    log_message "Updates installed successfully"
    return 0
}

# Function to show help
show_help() {
    echo "EndeavourOS Maintenance Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --check-only     Check for updates only"
    echo "  -b, --backup-only    Create backup only"
    echo "  -u, --update-only    Install updates only (no backup)"
    echo "  -f, --full           Check updates, create backup, and install updates"
    echo "  -s, --silent         Run in silent mode (minimal output)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Default behavior: Check for updates and create backup"
}

# Parse command line arguments
SILENT=false
CHECK_ONLY=false
BACKUP_ONLY=false
UPDATE_ONLY=false
FULL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--check-only)
            CHECK_ONLY=true
            shift
            ;;
        -b|--backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        -u|--update-only)
            UPDATE_ONLY=true
            shift
            ;;
        -f|--full)
            FULL_MODE=true
            shift
            ;;
        -s|--silent)
            SILENT=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_status "Unknown option: $1" "error"
            show_help
            exit 1
            ;;
    esac
done

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Main execution
print_status "EndeavourOS Maintenance Script started" "info"
log_message "Script started with PID: $$"

if $CHECK_ONLY; then
    check_updates
elif $BACKUP_ONLY; then
    create_backup
elif $UPDATE_ONLY; then
    if check_updates; then
        print_status "No updates available" "info"
    else
        install_updates
    fi
elif $FULL_MODE; then
    if check_updates; then
        print_status "No updates available, creating backup anyway..." "info"
        create_backup
    else
        print_status "Updates found. Creating backup before installing..." "info"
        if create_backup; then
            print_status "Backup completed. Installing updates..." "info"
            install_updates
        else
            print_status "Backup failed. Skipping update installation for safety." "error"
            exit 1
        fi
    fi
else
    # Default behavior: check updates and create backup
    check_updates
    create_backup
fi

print_status "Script completed" "success"
log_message "Script completed successfully"