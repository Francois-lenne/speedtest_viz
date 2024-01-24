#!/bin/bash

csv_output="output/output_speedtest.csv"
hdfs_directory="output"



# Verify that the hadoop cluster is existing if not create it



hadoop fs -test -e "$hdfs_directory"

if [ $? -ne 0 ]; then
    # Créer le répertoire s'il n'existe pas sur HDFS
    hadoop fs -mkdir -p "$hdfs_directory"
    echo "Le répertoire $hdfs_directory a été créé avec succès sur HDFS."
else
    echo "Le répertoire $hdfs_directory existe déjà sur HDFS."
fi


hadoop fs -test -e "$csv_output"

# Verify that the csv file is existing if not create it
if [ $? -ne 0 ]; then
    # Créer le fichier s'il n'existe pas sur HDFS
    echo "server_location;IP;latency;Jitter;100kB_speed;1MB_speed;10MB_speed;25MB_speed;100MB_speed;Download_speed;upload_speed;network;date;hour;city;postal;localisation;org;signal_strength" > $csv_output
    echo "Le fichier $csv_output a été créé avec succès sur HDFS."
else
    echo "Le fichier $csv_output existe déjà sur HDFS."
fi


# update the csv file in hadoop


network_name=$(networksetup -getairportnetwork en1 | cut -d ":" -f2 | sed -e 's/^ *//g' -e 's/ *$//g')

date=$(date +"%d/%m/%Y")

heure=$(date +"%T")

speed_test=$(npx speed-cloudflare-cli | cut -d ":" -f2 | tr '\n' ';' | sed 's/..$//' | sed 's/\x1b\[[0-9;]*m//g')

city=$(curl ipinfo.io | grep city | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

postal=$(curl ipinfo.io | grep postal | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

localisation=$(curl ipinfo.io | grep loc | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')

org=$(curl ipinfo.io | grep org | cut -d: -f2 | sed 's/\"//g' | sed 's/,//g')


echo $speed_test

# compute the wi fi forces

airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

# Obtenez les détails du réseau Wi-Fi
wifi_details=$($airport -I)

# Extraire la force du signal RSSI
signal_strength=$(echo "$wifi_details" | awk -F: '/ agrCtlRSSI: / {print $2}')


echo "$speed_test;$network_name;$date;$heure;$city;$postal;$localisation;$org;$signal_strength" >> $csv_output


# tail -c1 fichier.csv | read -r _ || echo >> $fichier


