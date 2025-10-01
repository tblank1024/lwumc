# Daily Announcment Display for Raspberry Pi4B to TV (lwumc)
Lake Washington United Methodist Church (Kirkland, WA) 

## General Description
Using a Raspberry Pi 4B, this program will continuously display a daily messsage 
to a chromium window in full screen mode using F11. Seven urls, one for each day are required. 
The display is refreshed every 6 hours starting at midnight in case announcement
changes are made. Finally, the system starts automatically at boot. The system can run
without a keyboard or mouse.

## System Setup
The following provides the steps to get the system working:
1. Build a Raspberry Pi OS image (updated to Bookworm 64 bit) with Python (I used Python 3.11.2)
2. Connect to internet either through ethernet or wifi
3. In cmd window: cd to location where you'd like the code to live
4. In cmd window: git clone https://github.com/tblank1024/lwumc.git
5. In cmd window: 
    sudo apt update
    sudo apt install python3-pip -y
    sudo python3 -m pip install --upgrade pip
    sudo pip3 install -r /path/to/requirements.txt

6. Using rasp-config:
- select boot to desktop
- select autologin
- (optional) VNC is enabled (see maintenance section)
8. Modify daily.py code to point at your 7 urls, one for each day. 
9. Create and start a systemd service to run the code (see systemd section for steps)
10. Reboot system and the program should start

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
5. In cmd window: sudo systemctl enable announcements.service
6. In cmd window: sudo systemctl start  announcements.service

## Security
Setting up the systemd service and installing python packages requires super user access using sudo.  
I was uncomfortable leaving the system continuously logged in with super user privilages so after setting everything 
up, using another account, I removed my selected account from the sudo group. Other security measures can be taken if
the system isn't in a secure location like disabling any unsed ports.  

##  Maintenance
The the system does not have a keyboard or mouse. VNC provides remote access when/if changes need to be made.  However, 
typical operation should not require any changes since only the 7 pages with daily announcements need to be modified; the urls
shouldn't be changed. Finally, I discovered that xrdp and the windows "remote desktop" didn't work properly; 
only RealVNC desktop worked with both a remote display and a display directly connected to the Pi.
