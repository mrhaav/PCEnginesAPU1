#!/bin/sh
# 
# mrhaav 2020-11-18
# Huawei ME909s-120 modem
# SIM PIN should be deactivated
# ^SYSCFGEX: "00",3FFFFFFF,1,2,7FFFFFFFFFFFFFFF


DEV=/dev/ttyUSB0
APN=internet
pdpType=IP


# Modem start up delay
sleep 1

# Set error codes to verbose
atOut=$(COMMAND="AT+CMEE=2" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2' | sed -e 's/[\r\n]//g')
while [ $atOut != 'OK' ]
do
	atOut=$(COMMAND="AT+CMEE=2" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2' | sed -e 's/[\r\n]//g')
done

# Check SIMcard and PIN status
atOut=$(COMMAND="AT+CPIN?" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2' | awk -F : '{print $2}' | sed -e 's/[\r\n]//g' | sed 's/^ *//g' | sed 's/ /q/g')
if [ $atOut == 'READY' ]
# Initiate modem
then
# Flight mode on
	atOut=$(COMMAND="AT+CFUN=0" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
# Disable unsolicted indications
	atOut=$(COMMAND="AT^CURC=0" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
# Modem manufacturer information
	atOut=$(COMMAND="AT+CGMI" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2')
	logger -t modem $atOut
# Modem model information
	atOut=$(COMMAND="AT+CGMM" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2')
	logger -t modem $atOut
# Configure PDPcontext
	atOut=$(COMMAND="AT+CGDCONT=0,\"$pdpType\",\"$APN\"" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
	atOut=$(COMMAND="AT+CGDCONT=1,\"$pdpType\",\"$APN\"" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
# Flight mode off
	atOut=$(COMMAND="AT+CFUN=1" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
# Check service status
	atOut=$(COMMAND="AT^SYSINFOEX" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | grep SYSINFOEX:)
	service="${atOut:12:3}"
	SIMstatus="${atOut:18:1}"
	if [ $SIMstatus != '1' ]
	then
		logger -t modem Invalid SIMcard
	elif [ $service != '2,3' ]
	then
		logger -t modem No service, check APN
	else
# Check operator
		atOut=$(COMMAND="AT+COPS?" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom | awk 'NR==2' | awk -F , '{print $3}' | sed -e 's/\"//g')
		logger -t modem Connected to $atOut
# Activate NDIS application
		atOut=$(COMMAND="AT^NDISDUP=1,1" gcom -d "$DEV" -s /etc/gcom/getruncommand.gcom)
	fi
else
	atOut=`echo "$atOut" | sed -e 's/q/ /g'`
	logger -t modem $atOut
fi
