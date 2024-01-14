# Python program that starts at 6AM and displays then updates the daily calendar every ~6 hours
# - 6AM, 12PM, 6PM, 12AM
# - The calendar is displayed in full screen mode
# The program is run on a Raspberry Pi 4B with connected to a TV monitor
# Systemd starts the program at boot time


import os
print("DISPLAY:", os.environ.get('DISPLAY', 'Not Set'))
import webbrowser
import pyautogui
from datetime import datetime

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

def DisplayURL(url,Sleeping_sec):
    global day_of_week, hour_of_day, minute_of_hour

    # Get the default browser controller 
    browser = webbrowser.get()

    # Open the URL with the specified browser and parameters
    browser.open("--app=" + url)

    # Wait for a short time to ensure the browser tab is fully loaded
    pyautogui.sleep(5)

    # Simulate pressing F11 to go full screen
    pyautogui.hotkey('F11')
    pyautogui.sleep(Sleeping_sec)       #seconds sleep

    # Simulate pressing Ctrl-W to close the tab
    pyautogui.hotkey('ctrl', 'w')  #close tab   
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
# - Daily calls DisplayURL every 6 hours starting at 6AM
def Main():
    global day_of_week, hour_of_day, minute_of_hour, URLS
    SIXHOURS = 21600    #seconds
    
    while True:
        Timing()
        url = URLS[day_of_week]
        print("URL: " + url)
        #Show diplay until next update time - 6AM, 12PM, 6PM, 12AM
        DisplayURL(url, CalculateSleepTime()+70)    #In case of a delay, add 70 seconds insuring midnight update is on next day


__name__ = "__main__"
debug = 0
if debug > 0:
    for tmp_day in range(0, 7):
        day_of_week = tmp_day
        Timing()
        DisplayURL(URLS[tmp_day],5)
print("starting main")
Main()
print("Will never get here.... Main is an infinite loop")

