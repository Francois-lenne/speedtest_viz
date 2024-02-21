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

