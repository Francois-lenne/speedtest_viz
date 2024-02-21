##!/bin/bash

# Verification that the tools needed is installed

## check if homebrew is installed

if ! command -v brew &> /dev/null
then
    echo "Homebrew is not installed"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    exit
fi

## Check if postegresql is installed

if ! command -v psql &> /dev/null
then
    echo "Postgresql is not installed"
    brew install postgresql
    exit
fi


## Check if metabse is installed else installed it

if ! command -v metabase &> /dev/null
then
    echo "Metabase is not installed"
    brew install metabase
    exit
fi

# Perform the speedtest 


speed_test=$(npx speed-cloudflare-cli | cut -d ":" -f2 | tr '\n' ';' | sed 's/..$//' | sed 's/\x1b\[[0-9;]*m//g')


# perform the curl of ipinfo.io

ip_info=$(curl ipinfo.io)




# defint the values form the speedtest running





# define the values from curl ipinfo.io in order to insert them in the postegre sql database

network_name=$(networksetup -getairportnetwork en1 | cut -d ":" -f2 | sed -e 's/^ *//g' -e 's/ *$//g')

date=$(date +"%d/%m/%Y")

heure=$(date +"%T")

speed_test=$(npx speed-cloudflare-cli | cut -d ":" -f2 | tr '\n' ';' | sed 's/..$//' | sed 's/\x1b\[[0-9;]*m//g')

city=$(ip_info | grep city | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

postal=$(ip_info| grep postal | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

localisation=$(ip_info| grep loc | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

org=$(ip_info| grep org | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')



echo $speed_test

# compute the wi fi forces

airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

# Obtenez les détails du réseau Wi-Fi
wifi_details=$($airport -I)

# Extraire la force du signal RSSI
signal_strength=$(echo "$wifi_details" | awk -F: '/ agrCtlRSSI: / {print $2}')



# definie if the network pass by wi-fi or ethernet 

# Obtenez l'interface réseau utilisée comme passerelle par défaut\n

default_interface=$(route -n get default | grep 'interface:' | awk '{print $2}')
# Vérifiez si l'interface est de type Wi-Fi ou Ethernet
if [[ $(ifconfig $default_interface | grep -i "inet " ) ]]; then
    if [[ $(networksetup -listallhardwareports | grep -B 1 -i "$default_interface" | awk '/Hardware Port/{ print }'|cut -d " " -f3-) == "Wi-Fi" ]]; then
           echo "Connecté via Wi-Fi"
            network_interface="wI-fI"
               else
                       echo "Connecté via Ethernet"
                       network_interface="ethernet"
                           fi
                           else
                              echo "Pas de connexion réseau"
                              fi





echo "$speed_test;$network_name;$date;$heure;$city;$postal;$localisation;$org;$signal_strength;$network_interface" >> $csv_output




# Upload in postegresql 

## verify that the test database is created

if ! psql -lqt | cut -d \| -f 1 | grep -qw test
then
    echo "Database test does not exist"
    psql -c "CREATE DATABASE test"
fi

## verify that the speedtest table is created

if ! psql -lqt | cut -d \| -f 1 | grep -qw speedtest
then
    echo "Table speedtest does not exist"
    psql -d test -c "CREATE TABLE speedtest (speed_test VARCHAR(255), network_name VARCHAR(255), date VARCHAR(255), heure VARCHAR(255), city VARCHAR(255), postal VARCHAR(255), localisation VARCHAR(255), org VARCHAR(255), signal_strength VARCHAR(255), network_interface VARCHAR(255))"
fi


## insert the values in the table

