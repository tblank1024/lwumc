#!/bin/bash
# Installation script for Lake Washington United Methodist Church (LWUMC) Calendar Display Service

echo "============================================"
echo "LWUMC Calendar Display Service Installer"
echo "============================================"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run with sudo"
    echo "Usage: sudo ./install-service.sh"
    exit 1
fi

# Get the current working directory (where the script is run from)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Installation directory: $SCRIPT_DIR"
echo ""

# Function to check if a user is root or has sudo privileges
is_privileged_user() {
    local username=$1
    local user_uid=$(id -u "$username" 2>/dev/null)
    
    # Check if UID is 0 (root)
    if [ "$user_uid" -eq 0 ]; then
        return 0  # true - is privileged
    fi
    
    # Check if user is in sudo or admin groups
    if groups "$username" 2>/dev/null | grep -qE '\b(sudo|admin|wheel|root)\b'; then
        return 0  # true - is privileged
    fi
    
    return 1  # false - not privileged
}

# Function to configure auto-login
configure_autologin() {
    local username=$1
    
    echo ""
    echo "Configuring automatic login for '$username'..."
    
    # Detect the display manager and configure accordingly
    if [ -f /etc/lightdm/lightdm.conf ]; then
        # LightDM configuration
        echo "Detected LightDM display manager"
        
        # Backup existing config (only if backup doesn't exist)
        if [ ! -f /etc/lightdm/lightdm.conf.backup ]; then
            cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
        fi
        
        # Remove any existing autologin configuration to avoid duplicates
        sed -i '/^autologin-user=/d' /etc/lightdm/lightdm.conf
        sed -i '/^autologin-user-timeout=/d' /etc/lightdm/lightdm.conf
        
        # Configure auto-login
        if grep -q "^\[Seat:\*\]" /etc/lightdm/lightdm.conf; then
            # Add autologin settings after [Seat:*] section
            sed -i "/^\[Seat:\*\]/a autologin-user-timeout=0" /etc/lightdm/lightdm.conf
            sed -i "/^\[Seat:\*\]/a autologin-user=$username" /etc/lightdm/lightdm.conf
        else
            # Add new [Seat:*] section
            echo "" >> /etc/lightdm/lightdm.conf
            echo "[Seat:*]" >> /etc/lightdm/lightdm.conf
            echo "autologin-user=$username" >> /etc/lightdm/lightdm.conf
            echo "autologin-user-timeout=0" >> /etc/lightdm/lightdm.conf
        fi
        
    elif [ -f /etc/X11/default-display-manager ] && grep -q "raspi-config" /etc/X11/default-display-manager; then
        # Raspberry Pi with raspi-config
        echo "Detected Raspberry Pi system"
        echo "Configuring auto-login using raspi-config..."
        
        # Use raspi-config to enable auto-login
        raspi-config nonint do_boot_behaviour B4
        
        # Also modify the user in the auto-login config
        if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
            # Update existing autologin configuration
            sed -i "s/--autologin [^ ]*/--autologin $username/" /etc/systemd/system/getty@tty1.service.d/autologin.conf
        fi
        
    elif systemctl list-unit-files | grep -q "gdm"; then
        # GDM (GNOME Display Manager)
        echo "Detected GDM display manager"
        
        # Backup existing config (only if backup doesn't exist)
        if [ ! -f /etc/gdm3/custom.conf.backup ]; then
            cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.backup 2>/dev/null || true
        fi
        
        # Remove existing autologin settings to avoid duplicates
        if [ -f /etc/gdm3/custom.conf ]; then
            sed -i '/^AutomaticLoginEnable=/d' /etc/gdm3/custom.conf
            sed -i '/^AutomaticLogin=/d' /etc/gdm3/custom.conf
            
            # Add autologin settings after [daemon] section
            sed -i "/\[daemon\]/a AutomaticLogin=$username" /etc/gdm3/custom.conf
            sed -i "/\[daemon\]/a AutomaticLoginEnable=true" /etc/gdm3/custom.conf
        fi
        
    elif [ -d /etc/sddm.conf.d ]; then
        # SDDM (Simple Desktop Display Manager - used by KDE)
        echo "Detected SDDM display manager"
        
        # Overwrite autologin config (idempotent - always creates fresh config)
        cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$username
Session=plasma.desktop
EOF
        
    else
        echo "WARNING: Could not detect display manager for auto-login configuration"
        echo "You may need to configure auto-login manually for user '$username'"
        return 1
    fi
    
    echo "✓ Auto-login configured for '$username'"
    return 0
}

# List available non-root users (excluding privileged users)
echo "Available non-privileged users on this system:"
NON_ROOT_USERS=""
while IFS=: read -r username _ uid _; do
    if [ "$uid" -ge 1000 ] && [ "$uid" -lt 65534 ]; then
        if ! is_privileged_user "$username"; then
            echo "  - $username (UID: $uid)"
            NON_ROOT_USERS="$NON_ROOT_USERS $username"
        fi
    fi
done < <(getent passwd)

if [ -z "$NON_ROOT_USERS" ]; then
    echo "  (No non-privileged users found)"
    DEFAULT_CREATE="Y"
else
    DEFAULT_CREATE="y"
fi
echo ""

# Ask if user wants to create a new user or use existing
read -p "Do you want to create a new user for the service? (${DEFAULT_CREATE}/n): " CREATE_USER
CREATE_USER=${CREATE_USER:-$DEFAULT_CREATE}

if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Creating a new non-root user for the calendar service..."
    echo ""
    
    # Prompt for new username
    while true; do
        read -p "Enter new username [lwumcdisplay]: " NEW_USERNAME
        NEW_USERNAME=${NEW_USERNAME:-lwumcdisplay}
        
        if [ -z "$NEW_USERNAME" ]; then
            echo "ERROR: Username cannot be empty."
            continue
        fi
        
        # Check if user already exists
        if id "$NEW_USERNAME" &>/dev/null; then
            echo "ERROR: User '$NEW_USERNAME' already exists. Please choose a different name."
            continue
        fi
        
        break
    done
    
    # Create the user with home directory
    echo "Creating user '$NEW_USERNAME'..."
    adduser --disabled-password --gecos "" "$NEW_USERNAME"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create user '$NEW_USERNAME'"
        exit 1
    fi
    
    # Add user to necessary groups for display access (but NOT sudo)
    echo "Adding user to video, audio, and input groups..."
    usermod -aG video,audio,input "$NEW_USERNAME"
    
    # Set a password for the user
    echo ""
    read -p "Do you want to set a password for '$NEW_USERNAME' now? (Y/n): " SET_PASSWORD
    SET_PASSWORD=${SET_PASSWORD:-Y}
    
    if [[ "$SET_PASSWORD" =~ ^[Yy]$ ]]; then
        passwd "$NEW_USERNAME"
        
        if [ $? -ne 0 ]; then
            echo "WARNING: Password not set. You can set it later with: sudo passwd $NEW_USERNAME"
        fi
    else
        echo "Skipping password setup. You can set it later with: sudo passwd $NEW_USERNAME"
    fi
    
    # Copy the code to the new user's home directory
    NEW_USER_HOME=$(eval echo ~$NEW_USERNAME)
    echo ""
    echo "Copying application files to $NEW_USER_HOME/lwumc..."
    mkdir -p "$NEW_USER_HOME/lwumc"
    cp -r "$SCRIPT_DIR"/* "$NEW_USER_HOME/lwumc/"
    chown -R "$NEW_USERNAME:$NEW_USERNAME" "$NEW_USER_HOME/lwumc"
    
    # Update SCRIPT_DIR to point to the new location
    SCRIPT_DIR="$NEW_USER_HOME/lwumc"
    
    SERVICE_USER="$NEW_USERNAME"
    
    echo ""
    echo "✓ User '$NEW_USERNAME' created successfully!"
    echo "✓ Files copied to: $SCRIPT_DIR"
    echo ""
else
    # Use existing user
    echo ""
    read -p "Enter the username to run the service: " SERVICE_USER
    
    # Validate input
    if [ -z "$SERVICE_USER" ]; then
        echo "ERROR: No username provided. Exiting."
        exit 1
    fi
    
    # Verify the user exists
    if ! id "$SERVICE_USER" &>/dev/null; then
        echo "ERROR: User '$SERVICE_USER' does not exist."
        echo "Run this script again and choose to create a new user."
        exit 1
    fi
    
    # Check if user is privileged (root or sudo)
    if is_privileged_user "$SERVICE_USER"; then
        echo ""
        echo "=========================================="
        echo "SECURITY ERROR"
        echo "=========================================="
        echo "User '$SERVICE_USER' has root/sudo privileges!"
        echo ""
        echo "Running GUI applications (like web browsers) with"
        echo "elevated privileges is a significant security risk."
        echo ""
        echo "Please either:"
        echo "  1. Run this script again and create a new non-privileged user"
        echo "  2. Use a different user without sudo access"
        echo ""
        exit 1
    fi
fi

# Ask about auto-login configuration
echo ""
read -p "Configure automatic login for '$SERVICE_USER' on boot? (Y/n): " CONFIGURE_AUTOLOGIN
CONFIGURE_AUTOLOGIN=${CONFIGURE_AUTOLOGIN:-Y}

if [[ "$CONFIGURE_AUTOLOGIN" =~ ^[Yy]$ ]]; then
    configure_autologin "$SERVICE_USER"
    AUTOLOGIN_CONFIGURED=$?
else
    echo "Skipping auto-login configuration."
    echo "WARNING: The service requires '$SERVICE_USER' to be logged into the desktop."
    AUTOLOGIN_CONFIGURED=1
fi

echo ""
echo "Configuring service for user: $SERVICE_USER"

# Get the user's home directory
USER_HOME=$(eval echo ~$SERVICE_USER)
echo "User home directory: $USER_HOME"
echo ""

# Verify Python script exists
if [ ! -f "$SCRIPT_DIR/src/daily.py" ]; then
    echo "ERROR: Cannot find daily.py at $SCRIPT_DIR/src/daily.py"
    exit 1
fi

# Create the service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/lwumc-calendar.service << EOF
[Unit]
Description=Lake Washington United Methodist Church (LWUMC) Daily Calendar Display
After=graphical.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Environment="DISPLAY=:0"
Environment="XAUTHORITY=$USER_HOME/.Xauthority"
WorkingDirectory=$SCRIPT_DIR/src
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/python3 $SCRIPT_DIR/src/daily.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

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
    read -p "Do you want to install chromium-browser now? (Y/n): " INSTALL_CHROMIUM
    INSTALL_CHROMIUM=${INSTALL_CHROMIUM:-Y}
    
    if [[ "$INSTALL_CHROMIUM" =~ ^[Yy]$ ]]; then
        echo "Installing chromium-browser..."
        apt-get update
        apt-get install -y chromium-browser
        
        if [ $? -eq 0 ]; then
            echo "✓ Chromium browser installed successfully!"
        else
            echo "ERROR: Failed to install chromium-browser"
            echo "You can install it manually later with: sudo apt-get install chromium-browser"
        fi
    else
        echo "Skipping Chromium installation."
        echo "You can install it later with: sudo apt-get install chromium-browser"
    fi
fi

# Check if unclutter is installed (for hiding cursor)
if ! command -v unclutter &> /dev/null; then
    echo ""
    echo "INFO: unclutter not found (used to hide mouse cursor on display)"
    read -p "Do you want to install unclutter now? (Y/n): " INSTALL_UNCLUTTER
    INSTALL_UNCLUTTER=${INSTALL_UNCLUTTER:-Y}
    
    if [[ "$INSTALL_UNCLUTTER" =~ ^[Yy]$ ]]; then
        echo "Installing unclutter..."
        apt-get install -y unclutter
        
        if [ $? -eq 0 ]; then
            echo "✓ unclutter installed successfully!"
        else
            echo "WARNING: Failed to install unclutter"
            echo "The display will work but the cursor may be visible"
            echo "You can install it manually later with: sudo apt-get install unclutter"
        fi
    else
        echo "Skipping unclutter installation."
        echo "Note: Mouse cursor will be visible on the display"
        echo "You can install it later with: sudo apt-get install unclutter"
    fi
fi

echo ""
echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
echo "Configuration Summary:"
echo "  Service User:    $SERVICE_USER"
echo "  Service Name:    lwumc-calendar"
echo "  Install Path:    $SCRIPT_DIR"
echo "  Python Script:   $SCRIPT_DIR/src/daily.py"
if [ $AUTOLOGIN_CONFIGURED -eq 0 ]; then
    echo "  Auto-login:      ✓ Enabled for '$SERVICE_USER'"
else
    echo "  Auto-login:      ✗ Not configured"
fi
echo ""
echo "SECURITY NOTE:"
echo "  ✓ Service runs as non-privileged user '$SERVICE_USER'"
echo "  ✓ This user does NOT have sudo/root access"
if [ $AUTOLOGIN_CONFIGURED -eq 0 ]; then
    echo "  ✓ User will automatically log in on boot"
fi
echo ""
echo "Service Management Commands (run as root/sudo user):"
echo "  Start now:       sudo systemctl start lwumc-calendar"
echo "  Stop:            sudo systemctl stop lwumc-calendar"
echo "  Restart:         sudo systemctl restart lwumc-calendar"
echo "  Status:          systemctl status lwumc-calendar  (no sudo needed)"
echo "  View logs:       journalctl -u lwumc-calendar -f  (no sudo needed)"
echo "  Disable:         sudo systemctl disable lwumc-calendar"
echo ""

if [ $AUTOLOGIN_CONFIGURED -eq 0 ]; then
    echo "Next Steps:"
    echo "  Simply reboot the system:"
    echo "    sudo reboot"
    echo ""
    echo "  The system will:"
    echo "    1. Automatically log in as '$SERVICE_USER'"
    echo "    2. Start the graphical desktop"
    echo "    3. Launch the calendar display service"
    echo ""
    echo "  No manual intervention required after reboot!"
else
    echo "Next Steps:"
    echo "  1. Reboot the system OR start the service manually now"
    echo ""
    echo "Option A - Reboot:"
    echo "  - Manually log in as '$SERVICE_USER' after reboot"
    echo "  - The service will start automatically after login"
    echo "  - Run: sudo reboot"
    echo ""
    echo "Option B - Start service manually now:"
    echo "  - Stay logged in as root/sudo user (don't log out yet)"
    echo "  - Run: sudo systemctl start lwumc-calendar"
    echo "  - Check: systemctl status lwumc-calendar"
    echo "  - Then log out and log in as '$SERVICE_USER'"
    echo ""
    echo "Note: For fully automatic startup, run this script again"
    echo "      and enable auto-login configuration."
fi

echo ""
