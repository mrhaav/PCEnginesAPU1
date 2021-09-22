#!/bin/sh
# Loopia API access
# Update Loopia DNS
# by mrhaav 2021-08-25
#  $1 = domain(inc subdomain)  $2 = IPaddress
#

username=mrhaav@loopiaapi
password=Openwrt.Router9

# Forced intervall, in seconds. 2592000 = 30 days. 0 turns off.
forcedUpdateTime=2592000


tempFolder=/var/loopia

mkdir -p $tempFolder


userID() {
# Create user id part of xml file
echo '  <params>' >> $tempFolder/$1
echo '    <param>' >> $tempFolder/$1
echo '      <value>'$username'</value>' >> $tempFolder/$1
echo '    </param>' >> $tempFolder/$1
echo '    <param>' >> $tempFolder/$1
echo '      <value>'$password'</value>' >> $tempFolder/$1
echo '    </param>' >> $tempFolder/$1
echo '    <param>' >> $tempFolder/$1
echo '      <value>'$domain'</value>' >> $tempFolder/$1
echo '    </param>' >> $tempFolder/$1
echo '    <param>' >> $tempFolder/$1
echo '      <value>'$subdomain'</value>' >> $tempFolder/$1
echo '    </param>' >> $tempFolder/$1

}


errorCheck() {

errorCode=$(xmllint --xpath //value/array/data/value/struct $tempFolder/$1 2>&1)

if [ "$errorCode" = 'XPath set is empty' ]
then
    errorCode=$(xmllint --xpath 'string(//value/array/data/value/string)' $tempFolder/$1)
    case "$errorCode" in
    "")
        logger -t ddns_d -p 3 'Loopia response: Check sub domain name <'$subdomain'>' ;;
    "AUTH_ERROR")
        logger -t ddns_d -p 3 'Loopia response: Check username and password' ;;
    "UNKNOWN_ERROR")
        logger -t ddns_d -p 3 'Loopia response: Ckeck domain name <'$domain'>' ;;
    *)
        logger -t ddns_d -p 3 'Loopia response: '$errorCode. ;;
    esac
    echo nOK
else
    echo OK
fi

}


checkDNS() {
# Create xml file
echo '<?xml version="1.0" encoding="UTF-8"?>' > $tempFolder/check_$subdomain.xml
echo '<methodCall>' >> $tempFolder/check_$subdomain.xml
echo '  <methodName>getZoneRecords</methodName>' >> $tempFolder/check_$subdomain.xml
userID check_$subdomain.xml
echo '  </params>' >> $tempFolder/check_$subdomain.xml
echo '</methodCall>' >> $tempFolder/check_$subdomain.xml

curl -d @$tempFolder/check_$subdomain.xml https://api.loopia.se/RPCSERV -s -o $tempFolder/status_$subdomain
xmllint --format $tempFolder/status_$subdomain --output $tempFolder/status_$subdomain.xml

errorStatus=$(errorCheck status_$subdomain.xml)
echo $errorStatus

}


updateDNS() {
local x=1

echo '<?xml version="1.0" encoding="UTF-8"?>' > $tempFolder/update_$subdomain.xml
echo '<methodCall>' >> $tempFolder/update_$subdomain.xml
echo '  <methodName>updateZoneRecord</methodName>' >> $tempFolder/update_$subdomain.xml
userID update_$subdomain.xml
echo '    <param>' >> $tempFolder/update_$subdomain.xml

Arecord=$(xmllint --xpath 'string(//data/value['$x']/struct/member[name="type"]/value/string)' $tempFolder/status_$subdomain.xml)
while [ "$Arecord" != "A" ] && [ ! -z "$Arecord" ]
do
    let "x+=1"
    Arecord=$(xmllint --xpath 'string(//data/value['$x']/struct/member[name="type"]/value/string)' $tempFolder/status_$subdomain.xml)
done

if [ "$Arecord" = "A" ]
then
    xmllint --xpath '//data/value['$x']/struct' $tempFolder/status_$subdomain.xml >> $tempFolder/update_$subdomain.xml

    echo '    </param>' >> $tempFolder/update_$subdomain.xml
    echo '  </params>' >> $tempFolder/update_$subdomain.xml
    echo '</methodCall>' >> $tempFolder/update_$subdomain.xml

    sed -i "s/$dnsIP/$newIP/" $tempFolder/update_$subdomain.xml

    curl -d @$tempFolder/update_$subdomain.xml https://api.loopia.se/RPCSERV -s -o $tempFolder/up_stat_$subdomain.xml

    xmllint --xpath 'string(//value/string)' $tempFolder/up_stat_$subdomain.xml
else
    logger -t ddns_d -p 3 No DNS A record found
    echo noA
fi

}


forcedUpdate() {

lastDate=$(ls --full-time $tempFolder/$1 2>/dev/null)
if [ ! -z "$lastDate" ]
then
    lastDate=${lastDate:44:19}
    lastTime=$(date +%s -d "$lastDate")
    nowTime=$(date +%s)
    
    timeToUpdate=$(($nowTime-$lastTime-$forcedUpdateTime))
    if [ $timeToUpdate -lt 0 ] || [ $forcedUpdateTime -eq 0 ]
    then
        echo No
    else
        echo Yes
    fi
else
    echo New
fi

}


# main

newIP=$2

domain=$(echo $1 | awk -F . '{print $(NF-1)"."$NF}')
subdomain=$(echo ${1%.$domain})
if [ $subdomain = $domain ]
then
    subdomain=@
fi

# DNSif=$(uci get network.$2.ifname 2>&1)
nsIP=$(nslookup $1 | grep 'Address 1:')
nsIP=$(echo ${nsIP#'Address 1: '})

checkForcedUpdate=$(forcedUpdate up_stat_$subdomain.xml)

if [ ! -z "$nsIP" ]
then
    if [ $newIP != $nsIP ] || [ $checkForcedUpdate != 'No' ]
    then
        checkStatus=$(checkDNS)
        if [ $checkStatus = 'OK' ]
        then
            dnsIP=$(xmllint --xpath 'string(//struct/member[name="rdata"]/value/string)' $tempFolder/status_$subdomain.xml)
            if [ $newIP != $dnsIP ] || [ $checkForcedUpdate != 'No' ]
            then
                updateStatus=$(updateDNS)
                if [ $updateStatus != 'OK' ]
                then
                    logger -t ddns_d -p 3 $1' DNS update went wrong:' $updateStatus
                else
                    logger -t ddns_d $1' DNS updated '$dnsIP' -> '$2 $updateStatus' Forced: '$checkForcedUpdate
                fi
            else
                logger -t ddns_d $1' Sub DNS not updated yet '$newIP' != '$nsIP
            fi
        fi
    else
        logger -t ddns_d $1' DNS up to date'
    fi
else
     logger -t ddns_d -p 3 $1' not found in local DNS'
fi
