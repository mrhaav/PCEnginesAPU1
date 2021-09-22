# OpenWrt and PC Engines APU1 project:

Check for latest firmware at: https://pcengines.github.io/
\
\
**Watchdog:**
`kmod-sp5100-tco`
\
\
**GPIO:**
`kmod-gpio-nct5104d`
\
\
**Temperature sensor:**
`lm-sensors`
\
\
**Loopia API**\
Hotplug script for updating Loopia DNS via LoopiaAPI. https://www.loopia.com/api/ \
`udhcpc.user` is triggered when the dhcp client is updating the IP-address.\
Copy `udhcpc.user` to `/etc` and `loopia.sh` to any folder of your choice. In `udhcpc.user` you have to map the interface to your domain_name to be updated. In `loopia.sh` you need to edit your username and password to LoopiaAPI.  \
You need to install `curl` and `libxml2-utils`.\
\
\
**ME909s-120**

How to enable Huawei ME909s-120 PCI modem. ME909s-120 doesn´t support QMI. Install packages:
```
kmod-usb-net-cdc-ether
kmod-usb-serial-option
comgt-ncm
```
Copy getruncommand.gcom to /etc/gcom.\
Copy huaweiME909s-120.sh to /etc, or any folder of your choice, and edit the APN to your local APN and DEV to your modem. You need to make huaweiME909s-120.sh executable `chmod +x huaweiME909s-120.sh`\
\
Add new interface...\
Name: wwan\
&nbsp;&nbsp;&nbsp;Protocol: DHCP client\
&nbsp;&nbsp;&nbsp;Interface: wwan0\
Firewall Settings: Create / Assign firewall-zone: add wwan to same zone as wan\
\
Execute huaweiME909s-120.sh at startup:\
System - Startup - Local Startup\
`sh /<your folder>/huaweiME909s-120.sh`\
\
Reboot\
\
\
**apu1-leds_buttom**

Kernel module to access the three front LEDs and the push button.\
LEDs are called apu:1, apu:2 and apu:3. The push buttom is accessible via GPIO and `cat /sys/class/gpio/gpio187/value`. 1 = unpressed, 0 = pressed.\
You can use packages like `kmod-ledtrig-netdev` to trigger the LEDs for network activity.\
\
\
**r8168-8.048.03**

NIC drivers to Realtek RTL8111E with support for customized LEDs.\
The APU1 board has LED0 (green) and LED1 (amber) connected. Default flashes LED0 for network activity, for all speeds, and LED1 is lit for Link100M.
I have change the drivers so LED0 is lit for Link, all speeds, and flashes for network activity, all speeds, and LED1 is lit for Link1G.\
That equals hex-word 0x004F, according to table:
|      | Activity | Link1G | Link100M | Link10M |
| --- | :---: | :---: | :---: | :---: | 
| LED0 | Bit3 | Bit2 | Bit1 | Bit0 |
| LED1 | Bit7 | Bit6 | Bit5 | Bit4 |
| N/A | Bit11 | Bit10 | Bit9 | Bit8 |
| LED3 | Bit15 | Bit14 | Bit13 | Bit12 |

If you want a different behavior, just change the hex-word in file r8168_n.c under section "Enable Custom LEDs".

Files "Realtek_" are the original files from the driver package, https://www.realtek.com/en/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-pci-express-software
