# MQTT based Solar Data Logger and Usage Automation 

This is adopted from MQTT-C example here, using the MQTT-C library: 
https://github.com/LiamBindle/MQTT-C

The data source is emonCMS: https://github.com/emoncms/emoncms

This is what's contained in this repository: 
- solar-mqtt.c : Data logging and electricity usage automation on Raspberry Pi 
- www : Website files for viewing the data logs with graphical representation 
- pc.c : Runs on PC to automatically control BOINC according to electricity usage 


Requirements for solar-mqtt.c: 

- MQTT source, publishing solar generation, export and usage. 
- Raspberry Pi (I used on version 3B and 4B, should work with all) 
- Setup a RAMdisk at /var/ramdisk (https://www.domoticz.com/wiki/Setting_up_a_RAM_drive_on_Raspberry_Pi) 
- Pimote and plugs from Energenie (see pc.c on how to comment out this part if you only want data logging) 
- wiringPi library for RaspberryPi GPIO interactions (not needed for data logging) 

Requirements for Raspbian Linux distro: 

- Install lighttpd and php-cgi (sudo apt install)
- Create symbolic links as detailed in LINKS.txt 
- For Raspberry Pi 4, install latest wiringPi: sudo dpkg -i wiringpi-252.deb 
(at time of writing, apt repo version is 2.50... http://wiringpi.com/wiringpi-updated-to-2-52-for-the-raspberry-pi-4b/)

The dataflow for solar-mqtt.c and www parts on Raspberry Pi: 

1. Raspberry Pi is connected to my home network 
2. MQTT message on the home network every 30 seconds it gets a new reading. 
3. There is a listener program always running on RPi (the compiled solar-mqtt.c) 
4. The listener program in RPi captures the broadcast and does 2 things:  
  a. Decides whether there is any export and turns on Pimote sockets and send WakeOnLan PC   
  b. Records its state and current usage/generation/export information into a file on RAMdisk (/var/ramdisk) 
5. Use any web browser navigate to RaspberryPi and see a graph and log files  (/var/www) 
6. At night, a bash script is run to archive the log file and trim the live log file if it's too big (solarlog-save.sh)
    Log files are archived at /home/pi/solar/log 

A few things to note: 

- The current log file will disappear if RPi power is interrupted. Use "sudo halt" command to safely shutdown RPi 
- On RPi, there should be the following:
  - 1 start up task: compiled ilm (or il)  This is also done in solarlog-persist.service. However, the service requires customisation to work out of box on Raspbian
  - 2 background scheduled tasks: solarlog-save.sh at 23:59, solarlog-persist.service sync every hour 
  - 1 systemd using solarlog-persist.service, which runs solarlog-persist 
- To build solar-mqtt.c, use comp.sh script 
- To build pc.c, no special command is needed, Linux or Cygwin environment recommended. 
- Inside LINKS.TXT details the links required for the graph webpage 
- The definition for log file columns are found near the end of C files 
- Attempt has been made to keep similarity between the C files so that the updates and bug fixes can be applied to both easily. 
