# Python program that starts at 6AM and displays then updates the daily calendar every ~6 hours
# - 6AM, 12PM, 6PM, 12AM
# - The calendar is displayed in full screen mode
# The program is run on a Raspberry Pi 4B with connected to a TV monitor
# Systemd starts the program at boot time
#
# Source maintained at: https://github.com/tblank1024/lwumc.git

# Import the required libraries
import subprocess
import time
from datetime import datetime
import signal
import os
import sys

#Constants
URLS =     ["https://lakewaumc.org/event-calendar-page-monday/",
            "https://lakewaumc.org/event-calendar-page-tuesday/",
            "https://lakewaumc.org/event-calendar-page-wednesday/",
            "https://lakewaumc.org/event-calendar-page-thursday/",
            "https://lakewaumc.org/event-calendar-page-friday/",
            "https://lakewaumc.org/event-calendar-page-saturday/",
            "https://lakewaumc.org/event-calendar-page-sunday/"]

#global variables
day_of_week = 0
hour_of_day = 0
minute_of_hour = 0
debug = 0
test_mode = 0  # Set to 1 to quickly test all 7 days
chrome_process = None
unclutter_process = None

def hide_cursor():
    """Hide the mouse cursor using unclutter or xdotool"""
    global unclutter_process
    
    try:
        # Try using unclutter (preferred method)
        unclutter_process = subprocess.Popen(['unclutter', '-idle', '0', '-root'],
                                             stdout=subprocess.DEVNULL,
                                             stderr=subprocess.DEVNULL)
        print("Cursor hidden using unclutter")
        return True
    except FileNotFoundError:
        try:
            # Alternative: use xdotool to move cursor off-screen
            subprocess.run(['xdotool', 'mousemove', '9999', '9999'],
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL,
                          check=True)
            print("Cursor moved off-screen using xdotool")
            return True
        except (FileNotFoundError, subprocess.CalledProcessError):
            print("Warning: Could not hide cursor (unclutter or xdotool not found)")
            print("Install with: sudo apt-get install unclutter")
            return False

def show_cursor():
    """Show the mouse cursor by stopping unclutter"""
    global unclutter_process
    
    if unclutter_process and unclutter_process.poll() is None:
        unclutter_process.terminate()
        unclutter_process.wait()
        print("Cursor restored")

def DisplayURL(url, Sleeping_sec):
    global chrome_process
    
    try:
        print(f"Displaying URL: {url} for {Sleeping_sec} seconds")
        
        # Chrome/Chromium command with kiosk mode flags for Raspberry Pi
        # These flags ensure proper full-screen display
        chrome_cmd = [
            'chromium-browser',
            '--kiosk',
            '--start-fullscreen',
            '--start-maximized',
            '--noerrdialogs',
            '--disable-infobars',
            '--disable-session-crashed-bubble',
            '--disable-translate',
            '--disable-features=TranslateUI',
            '--disable-save-password-bubble',
            '--no-first-run',
            '--disable-popup-blocking',
            '--disable-default-apps',
            '--disable-extensions',
            '--autoplay-policy=no-user-gesture-required',
            '--window-position=0,0',
            '--window-size=1920,1080',
            '--incognito',
            url
        ]
        
        # Set DISPLAY environment variable if not set (for systemd service)
        env = os.environ.copy()
        if 'DISPLAY' not in env:
            env['DISPLAY'] = ':0'
        
        # Launch Chrome in kiosk mode with proper environment
        chrome_process = subprocess.Popen(chrome_cmd, env=env, 
                                         stdout=subprocess.DEVNULL, 
                                         stderr=subprocess.DEVNULL)
        print(f"Chrome launched with PID: {chrome_process.pid}")
        
        # Give Chrome time to fully launch and go fullscreen
        time.sleep(3)
        
        # Keep the webpage displayed for the specified time
        time.sleep(Sleeping_sec)
        
        # Close Chrome process
        if chrome_process and chrome_process.poll() is None:
            print("Closing Chrome...")
            chrome_process.terminate()
            time.sleep(2)
            
            # Force kill if still running
            if chrome_process.poll() is None:
                chrome_process.kill()
            chrome_process.wait()
            
    except FileNotFoundError:
        print("Error: Chrome/Chromium browser not found. Trying alternative...")
        try:
            # Try google-chrome as alternative
            chrome_cmd[0] = 'google-chrome'
            env = os.environ.copy()
            if 'DISPLAY' not in env:
                env['DISPLAY'] = ':0'
            chrome_process = subprocess.Popen(chrome_cmd, env=env,
                                             stdout=subprocess.DEVNULL,
                                             stderr=subprocess.DEVNULL)
            time.sleep(3)
            time.sleep(Sleeping_sec)
            if chrome_process and chrome_process.poll() is None:
                chrome_process.terminate()
                chrome_process.wait()
        except Exception as e:
            print(f"Error: Could not launch Chrome. {e}")
            print("Please ensure chromium-browser or google-chrome is installed")
    except Exception as e:
        print(f"Error displaying URL: {e}")
        if chrome_process and chrome_process.poll() is None:
            chrome_process.terminate()
    
    chrome_process = None
    return

def Timing():
    global day_of_week, hour_of_day, minute_of_hour
    # Get the current date and time
    current_datetime = datetime.now() 
    day_of_week = current_datetime.weekday()    #get day of week
    hour_of_day = current_datetime.hour         #get hour of day (24 hr format)
    minute_of_hour = current_datetime.minute    #get minute of hour
    if debug > 0:
        print("Current date and time: " + str(current_datetime))
        print("Day of week: " + str(day_of_week))
        print("Hour of day: " + str(hour_of_day))
        print("Minute of hour: " + str(minute_of_hour))
        print("---------------------------------")
    return

def CalculateSleepTime():
    # Calculate the number of seconds until the next update at 6AM, 12PM, 6PM, 12AM
    global hour_of_day, minute_of_hour
    
    if hour_of_day < 6:
        sleep_time = (6 - hour_of_day) * 3600
    elif hour_of_day < 12:
        sleep_time = (12 - hour_of_day) * 3600
    elif hour_of_day < 18:
        sleep_time = (18 - hour_of_day) * 3600
    else:
        sleep_time = (24 - hour_of_day + 6) * 3600
    sleep_time = sleep_time - minute_of_hour * 60
    if debug > 0:
        print("Sleep time: " + str(sleep_time)) 
    return sleep_time

#main 
# - Calls DisplayURL every 6 hours at 6AM, 12PM, 6PM, 12AM
# - runs forever
def Main():
    global day_of_week, hour_of_day, minute_of_hour, URLS
    
    while True:
        Timing()
        url = URLS[day_of_week]
        print("URL: " + url)
        #Show display until next update time - 6AM, 12PM, 6PM, 12AM
        DisplayURL(url, CalculateSleepTime()+70)    #In case of a delay, add 70 seconds insuring midnight update is on next day

def TestAllDays():
    """Test mode - quickly cycle through all 7 days of the week"""
    global day_of_week, URLS
    
    print("=== TEST MODE: Cycling through all 7 days ===")
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    for tmp_day in range(0, 7):
        day_of_week = tmp_day
        print(f"\n--- Testing Day {tmp_day + 1}/7: {day_names[tmp_day]} ---")
        Timing()
        DisplayURL(URLS[tmp_day], 10)  # Display each page for 10 seconds
        print(f"Completed {day_names[tmp_day]}")
    
    print("\n=== TEST MODE COMPLETE: All 7 days tested ===")
    return

def cleanup(signum, frame):
    """Cleanup function to close Chrome and restore cursor on exit"""
    global chrome_process
    print("\nReceived signal to exit. Cleaning up...")
    if chrome_process and chrome_process.poll() is None:
        chrome_process.terminate()
        chrome_process.wait()
    show_cursor()
    exit(0)

if __name__ == "__main__":
    # Register signal handlers for clean shutdown
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    
    # Hide the mouse cursor
    hide_cursor()
    
    #degug mode - set to >0 to enable debug prints
    debug = 0  # Change to >0 to enable debug prints

    # Test mode - set to 1 to quickly test all 7 days
    test_mode = 0  # Change to 1 to enable test mode
    
    if test_mode > 0:
        TestAllDays()
        print("Exiting after test mode")
        show_cursor()
        exit(0)
    
    if debug > 0:
        for tmp_day in range(0, 7):
            day_of_week = tmp_day
            Timing()
            DisplayURL(URLS[tmp_day], 5)
    print("starting main")
    Main()
    print("Will never get here.... Main is an infinite loop")

