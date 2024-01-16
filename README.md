# Daily Announcment Display for Raspberry Pi4B to TV (lwumc)
Lake Washington United Methodist Church (Kirkland, WA) 

## General Description
The program will display a daily messsage to a chromium window 
in full screen mode using F11. Seven urls, one for each day are required. 
The display is refreshed every 6 hours starting at midnight in case
changes are made. Finally, the system starts automatically at
boot.  

## System Setup
The following provides the steps to get the system working:
1. Build a Raspberry Pi OS image with Python (I used Python 3.11)
2. In cmd window: cd to location where you'd like the code to live
3. In cmd window: git clone https://github.com/tblank1024/lwumc.git
4. In cmd window: python -m pip install -r requirements.txt5. 
6. Using rasp-config in system section, insure that both boot to desktop and auto login are selected
7. Modify daily.py code to point at your 7 urls, one for each day
8. Create and start a systemd service to run the code (see systemd section for steps)
9. reboot system and the program should start

## systemd service Setup
1. Create file: /etc/systemd/system/announcments.service
2. Code for file:
```
[Unit]
Description=Python Program using Chromium to display daily announements/schedule items

[Service]
ExecStart=/usr/bin/python3 /home/tblank2/code/tblank1024/lwumc/src/daily.py
Restart=always
User=announce
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
```

3. Modify the ExecStart line to point to the location of the daily.py file
4. Modify the User line to the name of the user you want to run the code
5. In cmd window: sudo systemctl enable annoouncements.service
6. In cmd window: sudo systemctl start announcements.service
