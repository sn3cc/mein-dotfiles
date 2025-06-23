#!/bin/bash

# Installation script for EndeavourOS Maintenance System
# This script sets up the maintenance script and systemd services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    case $2 in
        "info") echo -e "${BLUE}[INFO]${NC} $1" ;;
        "success") echo -e "${GREEN}[SUCCESS]${NC} $1" ;;
        "warning") echo -e "${YELLOW}[WARNING]${NC} $1" ;;
        "error") echo -e "${RED}[ERROR]${NC} $1" ;;
        *) echo "$1" ;;
    esac
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_status "This script must be run as root (use sudo)" "error"
   exit 1
fi

print_status "Installing EndeavourOS Maintenance System..." "info"

# Create backup directory
BACKUP_DIR="/backup/endeavouros"
print_status "Creating backup directory: $BACKUP_DIR" "info"
mkdir -p "$BACKUP_DIR"
chmod 755 "$BACKUP_DIR"

# Install the main script
SCRIPT_PATH="/usr/local/bin/endeavouros-maintenance.sh"
if [ -f "endeavouros-maintenance.sh" ]; then
    print_status "Installing main script to $SCRIPT_PATH" "info"
    cp endeavouros-maintenance.sh "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    chown root:root "$SCRIPT_PATH"
else
    print_status "Main script file not found. Please ensure endeavouros-maintenance.sh is in the current directory." "error"
    exit 1
fi

# Create systemd service files
print_status "Creating systemd service files..." "info"

# Daily update check service
cat > /etc/systemd/system/endeavouros-maintenance.service << 'EOF'
[Unit]
Description=EndeavourOS Maintenance - Update Check and Backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/endeavouros-maintenance.sh --check-only
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Daily update check timer
cat > /etc/systemd/system/endeavouros-maintenance.timer << 'EOF'
[Unit]
Description=Run EndeavourOS Maintenance daily
Requires=endeavouros-maintenance.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Weekly backup service
cat > /etc/systemd/system/endeavouros-backup.service << 'EOF'
[Unit]
Description=EndeavourOS Weekly Backup
After=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/endeavouros-maintenance.sh --backup-only
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Weekly backup timer
cat > /etc/systemd/system/endeavouros-backup.timer << 'EOF'
[Unit]
Description=Run EndeavourOS Backup weekly
Requires=endeavouros-backup.service

[Timer]
OnCalendar=weekly
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Set proper permissions for systemd files
chmod 644 /etc/systemd/system/endeavouros-*.service
chmod 644 /etc/systemd/system/endeavouros-*.timer

# Reload systemd and enable timers
print_status "Reloading systemd daemon..." "info"
systemctl daemon-reload

print_status "Enabling and starting timers..." "info"
systemctl enable endeavouros-maintenance.timer
systemctl enable endeavouros-backup.timer
systemctl start endeavouros-maintenance.timer
systemctl start endeavouros-backup.timer

# Create desktop entry for GUI access
print_status "Creating desktop entry..." "info"
cat > /usr/share/applications/endeavouros-maintenance.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=EndeavourOS Maintenance
Comment=System maintenance, updates, and backups
Exec=gnome-terminal -- sudo /usr/local/bin/endeavouros-maintenance.sh
Icon=system-software-update
Terminal=false
Categories=System;Settings;
Keywords=maintenance;backup;update;system;
EOF

chmod 644 /usr/share/applications/endeavouros-maintenance.desktop

# Install dependencies if needed
print_status "Checking dependencies..." "info"
DEPS_TO_INSTALL=""

if ! command -v rsync &> /dev/null; then
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL rsync"
fi

if [ -n "$DEPS_TO_INSTALL" ]; then
    print_status "Installing missing dependencies:$DEPS_TO_INSTALL" "info"
    pacman -S --noconfirm $DEPS_TO_INSTALL
fi

print_status "Installation completed successfully!" "success"
echo ""
print_status "The following has been set up:" "info"
echo "  • Main script: $SCRIPT_PATH"
echo "  • Daily update checks (via systemd timer)"
echo "  • Weekly backups (via systemd timer)"
echo "  • Backup directory: $BACKUP_DIR"
echo "  • Desktop entry for GUI access"
echo ""
print_status "Usage examples:" "info"
echo "  • Check for updates: sudo $SCRIPT_PATH --check-only"
echo "  • Create backup: sudo $SCRIPT_PATH --backup-only"
echo "  • Full maintenance: sudo $SCRIPT_PATH --full"
echo "  • View timer status: systemctl status endeavouros-maintenance.timer"
echo "  • View logs: journalctl -u endeavouros-maintenance.service"
echo ""
print_status "Timer status:" "info"
systemctl list-timers endeavouros-*

print_status "Installation complete! The system will now automatically check for updates daily and create backups weekly." "success"