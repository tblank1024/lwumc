#!/bin/bash
# Installation script for Lake Washington United Methodist Church (LWUMC) Calendar Display Service

echo "Installing Lake Washington United Methodist Church Calendar Display Service..."

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./install-service.sh"
    exit 1
fi

# Get the actual user (not root when using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
echo "Installing for user: $ACTUAL_USER"

# Copy service file to systemd directory
echo "Copying service file..."
cp lwumc-calendar.service /etc/systemd/system/

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling service to start on boot..."
systemctl enable lwumc-calendar.service

# Check if Chromium is installed
if ! command -v chromium-browser &> /dev/null && ! command -v google-chrome &> /dev/null; then
    echo ""
    echo "WARNING: Chromium browser not found!"
    echo "Please install it with: sudo apt-get install chromium-browser"
    echo ""
fi

echo ""
echo "Installation complete!"
echo ""
echo "Service commands:"
echo "  Start service now:    sudo systemctl start lwumc-calendar"
echo "  Stop service:         sudo systemctl stop lwumc-calendar"
echo "  Check status:         sudo systemctl status lwumc-calendar"
echo "  View logs:            sudo journalctl -u lwumc-calendar -f"
echo "  Disable autostart:    sudo systemctl disable lwumc-calendar"
echo ""
echo "The service will automatically start on next boot."
echo ""
