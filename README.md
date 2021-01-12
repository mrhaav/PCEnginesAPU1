# OpenWrt and PC Engines APU1 project:

apu1-leds_buttom

Kernel module to access the three front LEDs and the push button. LEDs are called apu:1, apu:2 and apu:3. The push buttom is accessible via GPIO and `cat /sys/class/gpio/gpio187/value`. 1 = unpressed, 0 = pressed.\
You can use packages like kmod-ledtrig-netdev to trigger the LEDs for network activity.


r8168-8.048.03

NIC drivers for RTL8111E with support for customized LEDs.

