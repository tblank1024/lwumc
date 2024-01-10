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

def DisplayURL(url,sleeping):
    # Open the URL in the default web browser
    webbrowser.open_new(url)

    # Wait for a short time to ensure the browser tab is fully loaded
    pyautogui.sleep(5)

    # Simulate pressing F11 to go full screen
    pyautogui.hotkey('F11')
    pyautogui.sleep(sleeping)       #seconds
    pyautogui.hotkey('ctrl', 'w')
    return

def Timing():
    global day_of_week, hour_of_day, minute_of_hour
    # Get the current date and time
    current_datetime = datetime.now() 
    day_of_week = current_datetime.weekday()    #get day of week
    hour_of_day = current_datetime.hour         #get hour of day (24 hr format)
    minute_of_hour = current_datetime.minute    #get minute of hour
    if debug > 1:
        print("Current date and time: " + str(current_datetime))
        print("Day of week: " + str(day_of_week))
        print("Hour of day: " + str(hour_of_day))
        print("Minute of hour: " + str(minute_of_hour))
    return

#main 
# - Daily calls DisplayURL at 1AM every day of the week
# - on Sunday also changes the display at 1PM
def Main():
    global day_of_week, hour_of_day, minute_of_hour, URLS
    
    while True:
        Timing()
        url = URLS[day_of_week]
        print("URL: " + url)
        if day_of_week == 6 and hour_of_day == 13:
            DisplayURL(url, 3600)   #seconds
        elif hour_of_day == 1:
            DisplayURL(url, 3600)   #seconds

    

__name__ = "__main__"
debug = 1
if debug > 0:
    for tmp_day in range(0, 7):
        day_of_week = tmp_day
        Timing()
        print("day_of_week: " + str(tmp_day))
        print("hour_of_day: " + str(hour_of_day))
        print("minute_of_hour: " + str(minute_of_hour))
        print("---------------------------------")
        DisplayURL(URLS[tmp_day],5)
print("starting main")
Main()
print("ending main")

