# OpenWrt and PC Engines APU1 project:

**apu1-leds_buttom**

Kernel module to access the three front LEDs and the push button.\
LEDs are called apu:1, apu:2 and apu:3. The push buttom is accessible via GPIO and `cat /sys/class/gpio/gpio187/value`. 1 = unpressed, 0 = pressed.\
You can use packages like kmod-ledtrig-netdev to trigger the LEDs for network activity.\
\
\
**r8168-8.048.03**

NIC drivers to Realtek RTL8111E with support for customized LEDs.\
The APU1 board has LED0 (green) and LED1 (amber) connected. Default flashes LED0 for network activity, for all speeds, and LED1 is lit for Link100M.
I have change the drivers so LED0 is lit for Link, all speeds, and flashes for network activity, all speeds, and LED1 is lit for Link1G.\
That equals hex-word 0x004F, according to table:
```
       | Activity | Link1G | Link100M | Link10M
 LED0  |  Bit3    |  Bit2  |  Bit1    |  Bit0
 LED1  |  Bit7    |  Bit6  |  Bit5    |  Bit4
 N/A   |  Bit11   |  Bit10 |  Bit9    |  Bit8
 LED3  |  Bit15   |  Bit14 |  Bit13   |  Bit12
```
If you want a different behavior, just change the hex-word in file r8168_n.c under section "Enable Custom LEDs".

Files "Realtek_" are the original files from the driver package, https://www.realtek.com/en/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-pci-express-software
