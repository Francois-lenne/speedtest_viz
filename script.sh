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

current_datetime=$(date '+%F %T')

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


# transform the data 


## Conversion for the latency and Jitter in milliseconds 
convertir_en_ms() {
  valeur=$1

  # Extraire l'unité de temps et la valeur numérique
  unit=$(echo $valeur | awk '{print $2}')
  num=$(echo $valeur | awk '{print $1}')

  # Convertir la valeur en millisecondes
  case $unit in
    "s")
      # Convertir de secondes en millisecondes
      num=$(echo "$num * 1000" | bc -l)
      ;;
    "ms")
      # Pas besoin de conversion
      ;;
    "µs")
      # Convertir de microsecondes en millisecondes
      num=$(echo "$num / 1000" | bc -l)
      ;;
    "ns")
      # Convertir de nanosecondes en millisecondes
      num=$(echo "$num / 1000000" | bc -l)
      ;;
    *)
      # Si l'unité n'est pas reconnue, retourner 0
      num=0
      ;;
  esac

  # Retourner la valeur convertie avec deux décimales
  echo $num | LC_ALL=C awk '{printf "%.2f\n", $0}'
}

# applied the function to the latency and Jitter variable
latency=$(convertir_en_ms "$latency")
Jitter=$(convertir_en_ms "$Jitter")








# apply the fonction convertir_en_mbps to the speed variables

convertir_en_mbps() {
  valeur=$1

  # Extraire l'unité de bande passante et la valeur numérique
  unit=$(echo $valeur | awk '{print $2}')
  num=$(echo $valeur | awk '{print $1}')

  # Convertir la valeur en mégabits par seconde
  case $unit in
    "Gbps")
      # Convertir de gigabits par seconde en mégabits par seconde
      num=$(echo "$num * 1000" | bc -l)
      ;;
    "Mbps")
      # Pas besoin de conversion
      ;;
    "Kbps")
      # Convertir de kilobits par seconde en mégabits par seconde
      num=$(echo "$num / 1000" | bc -l)
      ;;
    "bps")
      # Convertir de bits par seconde en mégabits par seconde
      num=$(echo "$num / 1000000" | bc -l)
      ;;
    *)
      # Si l'unité n'est pas reconnue, retourner 0
      num=0
      ;;
  esac

  # Retourner la valeur convertie avec deux décimales
  echo $num | LC_ALL=C awk '{printf "%.2f\n", $0}'
}


## apply the function 

speed_100kB=$(convertir_en_mbps "$speed_100kB")
speed_1MB=$(convertir_en_mbps "$speed_1MB")
speed_10MB=$(convertir_en_mbps "$speed_10MB")
speed_25MB=$(convertir_en_mbps "$speed_25MB")
speed_100MB=$(convertir_en_mbps "$speed_100MB")
Download_speed=$(convertir_en_mbps "$Download_speed")
upload_speed_substr=$(convertir_en_mbps "$upload_speed_substr")



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
        latency NUMERIC(7, 2),
        Jitter NUMERIC(7, 2),
        speed_100kB NUMERIC(7, 2),
        speed_1MB NUMERIC(7, 2),
        speed_10MB NUMERIC(7, 2),
        speed_25MB NUMERIC(7, 2),
        speed_100MB NUMERIC(7, 2),
        Download_speed NUMERIC(7, 2),
        upload_speed NUMERIC(7, 2),
        network TEXT,
        datetime TIMESTAMP,
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
    datetime,
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
    '$current_datetime',
    '$city',
    '$postal',
    '$localisation',
    '$org',
    '$signal_strength',
    '$network_interface'
);"


postal=$(echo $postal | xargs)
echo "Postal code is $postal"


# Creation of the tables 

# Create the table for the clouflare server
psql -U "$username" -d speed_test -c "
CREATE TABLE IF NOT EXISTS cloudflare_server (
    id_server SERIAL PRIMARY KEY,
    server_name VARCHAR(255) NOT NULL UNIQUE
);"



# Vérifiez si une ligne avec le server_name spécifié existe déjà
server_name=$(psql -U "$username" -d speed_test -t -c "
SELECT server_name FROM cloudflare_server WHERE server_name = '$server_location';
")

# Supprimez les espaces blancs autour de server_name
server_name=$(echo $server_name | xargs)

echo "Server name is $server_name"

if [ ! -z "$server_name" ]
then
    echo "Pas d'ajout"
    server_id=$(psql -U "$username" -d speed_test -t -c "
  SELECT id_server FROM cloudflare_server WHERE server_name = '$server_location';
    ")
else
    echo "Variable à ajouter : $server_location"
    psql -U "$username" -d speed_test -c "
    INSERT INTO cloudflare_server (server_name) 
    VALUES ('$server_location');
    "


    server_id=$(psql -U "$username" -d speed_test -t -c "
    SELECT id_server FROM cloudflare_server WHERE server_name = '$server_location';
    ") 
fi

server_id=$(echo $server_id | xargs)

echo "Server ID is $server_id"



# Create the table for the ISP
psql -U "$username" -d speed_test -c "
CREATE TABLE IF NOT EXISTS isp (
    id_isp SERIAL PRIMARY KEY,
    isp_name VARCHAR(255) NOT NULL UNIQUE
);"



# Vérifiez si une ligne avec le server_name spécifié existe déjà
isp_name=$(psql -U "$username" -d speed_test -t -c "
SELECT isp_name FROM isp WHERE isp_name = '$org';
")

# Supprimez les espaces blancs autour de server_name
isp_name=$(echo $isp_name | xargs)

echo "isp name is $isp_name"

if [ ! -z "$isp_name" ]
then
    echo "Pas d'ajout"
    isp_id=$(psql -U "$username" -d speed_test -t -c "
  SELECT id_isp FROM isp WHERE isp_name = '$org';
    ")
else
    echo "Variable à ajouter : $org"
    psql -U "$username" -d speed_test -c "
    INSERT INTO isp (isp_name) 
    VALUES ('$org');
    "


    isp_id=$(psql -U "$username" -d speed_test -t -c "
    SELECT id_isp FROM isp WHERE isp_name = '$org';
    ") 
fi

isp_id=$(echo $isp_id | xargs)

echo "ISP ID is $isp_id"









# Create the table for the IP
psql -U "$username" -d speed_test -c "
CREATE TABLE IF NOT EXISTS ip (
    ip_id SERIAL PRIMARY KEY,
    ip_adress VARCHAR(255) NOT NULL UNIQUE
);"



# Vérifiez si une ligne avec le server_name spécifié existe déjà
ip_adress=$(psql -U "$username" -d speed_test -t -c "
SELECT ip_adress FROM ip WHERE ip_adress = '$IP';
")

# Supprimez les espaces blancs autour de server_name
ip_adress=$(echo $ip_adress | xargs)

echo "IP adress is $isp_name"

if [ ! -z "$ip_adress" ]
then
    echo "Pas d'ajout"
    ip_id=$(psql -U "$username" -d speed_test -t -c "
  SELECT ip_id FROM ip WHERE ip_adress = '$IP';
    ")
else
    echo "Variable à ajouter : $IP"
    psql -U "$username" -d speed_test -c "
    INSERT INTO ip (ip_adress) 
    VALUES ('$IP');
    "


    ip_id=$(psql -U "$username" -d speed_test -t -c "
    SELECT ip_id FROM ip WHERE ip_adress = '$IP';
    ") 
fi

ip_id=$(echo $ip_id | xargs)

echo "IP ID is $ip_id"


psql -U "$username" -d speed_test -c "
CREATE TABLE IF NOT EXISTS localisation (
    id_loc SERIAL PRIMARY KEY,
    city VARCHAR(255),
    postal_code NUMERIC(10, 0),
    coordinates VARCHAR(255),
    ip_id INTEGER,
    FOREIGN KEY (ip_id) REFERENCES ip(ip_id)
);
"

# Vérifiez si une ligne avec le server_name spécifié existe déjà
loc=$(psql -U "$username" -d speed_test -t -c "
SELECT coordinates FROM localisation WHERE coordinates = '$localisation';
")

# Supprimez les espaces blancs
loc=$(echo $loc | xargs)

echo "localisation is $loc"

if [ ! -z "$loc" ]
then
    echo "Pas d'ajout"
    loc_id=$(psql -U "$username" -d speed_test -t -c "
  SELECT id_loc FROM localisation WHERE coordinates = '$localisation';
    ")
else
    echo "Variable à ajouter : $city, $postal, $localisation, $ip_id"
    psql -U "$username" -d speed_test -c "
    INSERT INTO localisation (city, postal_code, coordinates, ip_id) 
    VALUES ('$city', '$postal', '$localisation', '$ip_id');
    "
    loc_id=$(psql -U "$username" -d speed_test -t -c "
    SELECT id_loc FROM localisation WHERE coordinates = '$localisation';
    ") 
fi

loc_id=$(echo $loc_id | xargs)

echo "loc ID is $loc_id"


