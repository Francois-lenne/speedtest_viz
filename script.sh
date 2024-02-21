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


## Check if metabase is installed else installed it

if ! command -v metabase &> /dev/null
then
    echo "Metabase is not installed"
    brew install metabase
    exit
fi

# Check if node.js is installed else installed it
if ! command -v node &> /dev/null; then
    echo "Node.js is installed"
    brew install node
else
    echo "Node.js already installed"
fi




## Verify that the service is activated

## verify for postegre
if ! brew services list | grep -q 'postgresql.*started'; then
    echo "starting PostgreSQL..."
    brew services start postgresql
else
    echo "Poostegre is already started"
fi

## verify for metabase
if ! brew services list | grep -q 'metabase.*started'; then
    echo "starting Metabase..."
    brew services start metabase
else
    echo "Metabase is already started"
fi


# Perform the speedtest 


speed_test=$(npx speed-cloudflare-cli | cut -d ":" -f2 | tr '\n' ';' | sed 's/..$//' | sed 's/\x1b\[[0-9;]*m//g')


# define the values form the speedtest running

server_location=$(echo $speed_test | cut -d ";" -f1)
IP=$(echo $speed_test | cut -d ";" -f2)
latency=$(echo $speed_test | cut -d ";" -f3)
Jitter=$(echo $speed_test | cut -d ";" -f4)
speed_100kB=$(echo $speed_test | cut -d ";" -f5)
speed_1MB=$(echo $speed_test | cut -d ";" -f6)
speed_10MB=$(echo $speed_test | cut -d ";" -f7)
speed_25MB=$(echo $speed_test | cut -d ";" -f8)
speed_100MB=$(echo $speed_test | cut -d ";" -f9)
Download_speed=$(echo $speed_test | cut -d ";" -f10)
upload_speed=$(echo $speed_test | cut -d ";" -f11)



# define the variable time 

date=$(date +"%d/%m/%Y")

heure=$(date +"%T")

# define the values from curl ipinfo.io in order to insert them in the postegre sql database

network_name=$(networksetup -getairportnetwork en1 | cut -d ":" -f2 | sed -e 's/^ *//g' -e 's/ *$//g')


city=$(curl ipinfo.io | grep city | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')
postal=$(curl ipinfo.io| grep postal | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')
localisation=$(curl ipinfo.io| grep loc | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')
org=$(curl ipinfo.io| grep org | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

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





# delete some ASCII character from the upload_speed variable

upload_speed_substr=${upload_speed%%s*}
upload_speed_substr+="s"


# Upload in postegresql 

## verify that the test database is created


username=$(whoami)

if ! psql -U "$username" -lqt | cut -d \| -f 1 | grep speed_test
then
    echo "Database test does not exist"
    createdb -U "$username" speed_test
else
    echo "Database speed_test already exist" 
fi

## verify that the speedtest table is created


if ! psql -U "$username" -d speed_test -c "\dt" | grep speedtest_upload
then
    echo "Table speedtest does not exist"
    psql -U "$username" -d speed_test -c "CREATE TABLE speedtest_upload (
        server_location TEXT,
        IP TEXT,
        latency TEXT,
        Jitter TEXT,
        speed_100kB TEXT,
        speed_1MB TEXT,
        speed_10MB TEXT,
        speed_25MB TEXT,
        speed_100MB TEXT,
        Download_speed TEXT,
        upload_speed TEXT,
        network TEXT,
        date DATE,
        hour TIME,
        city TEXT,
        postal INT,
        localisation TEXT,
        org TEXT,
        signal_strength INT,
        network_interface TEXT
    );"
else
    echo "Table speedtest_upload already exist"
fi


# Insert the values in the table
# Insert the values in the table
# Insert the values in the table
psql -U "$username" -d speed_test -c "
SET DateStyle = 'European';
INSERT INTO speedtest_upload (
    server_location,
    IP,
    latency,
    Jitter,
    speed_100kB,
    speed_1MB,
    speed_10MB,
    speed_25MB,
    speed_100MB,
    Download_speed,
    upload_speed,
    network,
    date,
    hour,
    city,
    postal,
    localisation,
    org,
    signal_strength,
    network_interface
) VALUES (
    '$server_location',
    '$IP',
    '$latency',
    '$Jitter',
    '$speed_100kB',
    '$speed_1MB',
    '$speed_10MB',
    '$speed_25MB',
    '$speed_100MB',
    '$Download_speed',
    '$upload_speed_substr',
    '$network_name',
    '$date',
    '$heure',
    '$city',
    '$postal',
    '$localisation',
    '$org',
    '$signal_strength',
    '$network_interface'
);"

# print the table
psql -U "$username" -d speed_test -c "
SET DateStyle = 'European';
SELECT * FROM speedtest_upload;"



