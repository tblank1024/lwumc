# Lake Washington United Methodist Church (LWUMC) Daily Calendar Display

Python program that displays the daily calendar for Lake Washington United Methodist Church on a TV monitor connected to a Raspberry Pi.

## Features

- Displays the daily calendar in full-screen kiosk mode
- Updates automatically at 6AM, 12PM, 6PM, and 12AM
- Runs continuously and restarts on failure
- Autostart on system boot using systemd

## Requirements

- Raspberry Pi (tested on Raspberry Pi 4B)
- Raspbian/Raspberry Pi OS with desktop environment
- Python 3 (built-in, no additional packages required)
- Chromium browser

## Installation

### 1. Install Chromium Browser (if not already installed)

```bash
sudo apt-get update
sudo apt-get install chromium-browser
```

### 2. Clone the Repository

```bash
cd ~
git clone https://github.com/tblank1024/lwumc.git
cd lwumc
```

### 3. Install the Systemd Service (Autostart on Boot)

```bash
chmod +x install-service.sh
sudo ./install-service.sh
```

This will:
- Copy the service file to `/etc/systemd/system/`
- Enable the service to start automatically on boot
- Configure the service to restart on failure

### 4. Start the Service

```bash
sudo systemctl start lwumc-calendar
```

## Usage

### Service Management

```bash
# Check service status
sudo systemctl status lwumc-calendar

# Start the service
sudo systemctl start lwumc-calendar

# Stop the service
sudo systemctl stop lwumc-calendar

# Restart the service
sudo systemctl restart lwumc-calendar

# View live logs
sudo journalctl -u lwumc-calendar -f

# Disable autostart on boot
sudo systemctl disable lwumc-calendar

# Enable autostart on boot
sudo systemctl enable lwumc-calendar
```

### Manual Testing

To run the program manually for testing:

```bash
cd ~/lwumc/src
python3 daily.py
```

**Note:** The program has a test mode enabled by default. Edit `daily.py` and set `test_mode = 0` to run in production mode.

## Configuration

### Test Mode

In `src/daily.py`, you can configure:

```python
# Test mode - cycles through all 7 days quickly (10 seconds each)
test_mode = 1  # Set to 0 for production mode

# Debug mode - enables detailed logging
debug = 0  # Set to >0 to enable debug prints
```

### Calendar URLs

The URLs for each day of the week are defined in the `URLS` array in `daily.py`.

## Troubleshooting

### Service won't start

1. Check the logs: `sudo journalctl -u lwumc-calendar -e`
2. Verify Chromium is installed: `which chromium-browser`
3. Check the DISPLAY variable: `echo $DISPLAY`

### Chrome/Chromium not found

Install the browser:
```bash
sudo apt-get install chromium-browser
```

### Display issues

Make sure you're running the service as the user who is logged into the desktop environment. The service file is configured for user `lwumcroot` by default.

### Disable test mode

Edit `src/daily.py` and change:
```python
test_mode = 0  # Disable test mode for production
```

Then restart the service:
```bash
sudo systemctl restart lwumc-calendar
```

## Development

The program uses only Python standard library modules:
- `subprocess` - For launching Chromium browser
- `time` - For sleep delays
- `datetime` - For time calculations
- `signal` - For clean shutdown handling
- `os` - For environment variables

## License

See LICENSE file for details.

## Source

Maintained at: https://github.com/tblank1024/lwumc.git
