# Lake Washington United Methodist Church (LWUMC) Daily Calendar Display

Python program that displays the daily calendar for Lake Washington United Methodist Church on a TV monitor connected to a Raspberry Pi.

## Features

- Displays the daily calendar in full-screen kiosk mode
- Updates automatically at 6AM, 12PM, 6PM, and 12AM
- Runs continuously and restarts on failure
- Automatic startup on system boot with auto-login
- Hidden mouse cursor for clean display
- Runs as non-privileged user for security

## Requirements

- Raspberry Pi (tested on Raspberry Pi 4B)
- Raspbian/Raspberry Pi OS with desktop environment
- Python 3 (built-in, no additional packages required)
- Chromium browser (installed automatically by setup script)
- unclutter (installed automatically by setup script)

## Quick Start Installation

### 1. Clone the Repository

```bash
cd ~
git clone https://github.com/tblank1024/lwumc.git
cd lwumc
```

### 2. Run the Automated Installer

```bash
chmod +x install-service.sh
sudo ./install-service.sh
```

The installer will:
- ✓ Create a non-privileged user for running the display (or use an existing one)
- ✓ Copy application files to the user's home directory
- ✓ Configure automatic login on boot
- ✓ Install Chromium browser (if needed)
- ✓ Install unclutter for cursor hiding (if needed)
- ✓ Create and enable the systemd service
- ✓ Configure the service to start automatically

### 3. Reboot

```bash
sudo reboot
```

That's it! After reboot, the system will automatically:
1. Log in as the calendar display user
2. Start the graphical desktop
3. Launch the calendar display with hidden cursor

**No manual intervention needed!**

## Installation Details

### User Account

The installer creates (or uses) a non-privileged user account to run the calendar display. This is important for security:

- The display user does **not** have sudo/root privileges
- GUI applications (especially web browsers) should never run as root
- The installer prevents you from using privileged accounts

**Default username:** `lwumcdisplay` (you can choose a different name)

### File Locations

When installed, files are located at:
- Application: `/home/<username>/lwumc/`
- Service file: `/etc/systemd/system/lwumc-calendar.service`
- LightDM config: `/etc/lightdm/lightdm.conf` (auto-login settings)

### Re-running the Installer

The installer is **idempotent** - safe to run multiple times:
- Updates code files to match your source directory
- Reconfigures the service with correct paths
- Updates auto-login settings without creating duplicates
- Re-installs missing dependencies

Use this to update the deployed installation after making code changes.

## Service Management

All service commands require sudo privileges:

```bash
# Start the service
sudo systemctl start lwumc-calendar

# Stop the service
sudo systemctl stop lwumc-calendar

# Restart the service
sudo systemctl restart lwumc-calendar

# View service status (no sudo needed)
systemctl status lwumc-calendar

# View live logs (no sudo needed)
journalctl -u lwumc-calendar -f

# Disable autostart on boot
sudo systemctl disable lwumc-calendar

# Re-enable autostart on boot
sudo systemctl enable lwumc-calendar
```

## Configuration

### Test Mode

The program includes a test mode that cycles through all 7 days quickly (10 seconds each) for testing purposes.

Edit `/home/<username>/lwumc/src/daily.py`:

```python
# Test mode - cycles through all 7 days quickly (10 seconds each)
test_mode = 1  # Set to 1 to enable test mode, 0 for production

# Debug mode - enables detailed logging
debug = 0  # Set to >0 to enable debug prints
```

After changing settings, restart the service:
```bash
sudo systemctl restart lwumc-calendar
```

### Calendar URLs

The URLs for each day of the week are defined in the `URLS` array in `daily.py`:

```python
URLS = ["https://lakewashingtonumc.org/event-calendar-page-monday/",
        "https://lakewashingtonumc.org/event-calendar-page-tuesday/",
        ...
```

### Update Schedule

The calendar updates automatically at:
- 6:00 AM
- 12:00 PM (Noon)
- 6:00 PM
- 12:00 AM (Midnight)

## Troubleshooting

### Service won't start

Check the service status and logs:
```bash
systemctl status lwumc-calendar
journalctl -u lwumc-calendar -e
```

Common issues:
- Display user not logged into desktop (check auto-login configuration)
- Incorrect file paths (re-run installer to fix)
- Missing dependencies (re-run installer to install)

### Display not showing

1. Verify Chromium is installed:
   ```bash
   which chromium-browser
   ```

2. Check the DISPLAY variable:
   ```bash
   echo $DISPLAY
   ```
   Should show `:0` or `:1`

3. Verify the display user is logged in:
   ```bash
   who
   ```

### Cursor still visible

Install unclutter if not already installed:
```bash
sudo apt-get install unclutter
```

Then restart the service:
```bash
sudo systemctl restart lwumc-calendar
```

### Auto-login not working

Check the LightDM configuration:
```bash
sudo cat /etc/lightdm/lightdm.conf | grep autologin
```

Should show:
```
autologin-user=lwumcdisplay
autologin-user-timeout=0
```

To reconfigure auto-login, run the installer again.

### Permission errors

If you see permission errors, ensure files are owned by the display user:
```bash
sudo chown -R lwumcdisplay:lwumcdisplay /home/lwumcdisplay/lwumc
```

## Manual Installation (Advanced)

If you prefer not to use the automated installer, see the service file and script for manual setup steps. However, the automated installer is recommended for reliability and security.

## Development

### Technology Stack

The program uses only Python standard library modules:
- `subprocess` - For launching Chromium browser
- `time` - For sleep delays  
- `datetime` - For time calculations
- `signal` - For clean shutdown handling
- `os` - For environment variables
- `sys` - For system operations

No external Python packages required (requirements.txt is empty).

### System Dependencies

- `chromium-browser` - Web browser for display
- `unclutter` - Hides mouse cursor
- `systemd` - Service management
- LightDM or other display manager - For auto-login

### Testing

To test the display without installing as a service:

1. Log in as the display user
2. Run manually:
   ```bash
   cd ~/lwumc/src
   python3 daily.py
   ```

Enable test mode in the script to quickly cycle through all days.

## Security Notes

- ✓ Service runs as non-privileged user (no sudo access)
- ✓ Browser runs in incognito mode
- ✓ No passwords or sensitive data stored
- ✓ Auto-login is safe for dedicated kiosk displays
- ✗ Do not use this setup on a multi-purpose computer

## License

GNU General Public License v3.0 - See LICENSE file for details.

## Source Code

Maintained at: https://github.com/tblank1024/lwumc.git

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review service logs: `journalctl -u lwumc-calendar -f`
3. Re-run the installer: `sudo ./install-service.sh`
4. Open an issue on GitHub
