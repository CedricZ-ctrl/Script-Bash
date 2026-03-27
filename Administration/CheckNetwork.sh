#!/bin/bash
#================================================================================================================#
#                   Description Script ChecNetwork                                                               #
# this script allows you to perform an initial diagnostic on the network part of the system including            #
# tcpdump, mtr, ip route, and any more command for the diagnostic                                                #
#                                                                                                                #       
#================================================================================================================#

# set -o pipefail, force the pipeline return the exitcode  of the first command example for : "result=$({ df -h $filesystem | tr -s ' ' | cut -d ' ' -f5,6 | tail -1; } 2>&1)"
# the set -o pipefail will get the resultat of "df -h" instead of tail -1
set -o pipefail

#format date for the logs 
function Date {
date '+%Y-%m-%d %H:%M:%S'
}
# array for the function InfoNetworkInterfaces 
arrayinterfaces=()

#arry for the function CheckSoft 
arraysoft=("ip" "mtr" "tcpdump")

#some required privileges root 
if [ "$EUID" -ne 0 ];then
        echo "launch the script with privilege root"
        exit
fi
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/CheckNetwork.log"

SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(Date)
        if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example to use : write-log  "the regex found" "INFO"
function write-log {
        local message="$1"
        local event="$2"
        local timestamp=$(Date)

        if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi
        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

function EndLog {
    local timestamp=$(Date)

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}
# 'trap' here ensure endlog function run if the script exits unexpectedly or when the user enters q | Q to quit.
trap EndLog EXIT INT 


function InfoNetworkInterfaces {
    getinterfaces=$(ip a | tr -s ' ' | grep "BROADCAST" -A 2 | cut -d ' ' -f2-3)
    
if [[ -n "$getinterfaces" ]]; then
    mapfile -t arrayinterfaces <<< "$getinterfaces"

    for iface in "${arrayinterfaces[@]}"; do
    echo "$iface"

    write-log "interface and ip : $iface " "INFO"
    done
else
echo "variable getinterfaces empty ! "
write-log "variable getinterfaces empty ! " "ERROR"
fi 
}

function iproutes {
    routes=$(ip route)

    if [[ -n "$routes" ]]; then
    echo "$routes"
    write-log "Info Route : $routes" "INFO"
    else 
    write-log "No informations routes found on the host" "ERROR"
    return 1
    fi
}
function ethtoolsinterfaces {
    
   interfaces=$(printf '%s\n' "${arrayinterfaces[@]}" | grep "BROADCAST" -B 0 | grep -v "\--" | cut -d ' ' -f1 )
   ifacethool=()
    if [[ -n "$interfaces" ]]; then
    mapfile -t ifacethool <<< "$interfaces"

    for iface in "${ifacethool[@]}"; do
    write-log "Name Interface found : $iface" "INFO"

    result1=$(ethtool  "$iface")
    echo "Resultat of command ethtool $iface: $result1"
    write-log "Resultat of command ethtool "$iface": $result1 " "INFO"
    done 

    else
    write-log "interface name not found" "ERROR"
    fi 
}

function traceroute {
    input=""
    read -p "Give me a IP or DNS Name of your target : " input

    if [[ -n "$input" ]]; then
        command=$(mtr -o 'J M X LSR NA B W V' -wzbc 20 $input)
        echo "$command:[test end with  target $input]"
        write-log "MTR on target : $input : $command " "INFO"
    else
        write-log "no information for testing routage" "ERROR"
    fi
}

function testtcpdump {
    #InfoNetworkInterfaces
    interfaces=$(printf '%s\n' "${arrayinterfaces[@]}" | grep "BROADCAST" -B 0 | grep -v "\--" | cut -d ' ' -f1 )
    ifacenet=()
    if [[ -n "$interfaces" ]]; then
        mapfile -t ifacenet <<< "$interfaces"

        for iface in "${ifacenet[@]}"; do 
        echo "RESULTAT COMMAND tcpdump : $iface "
        command=$(tcpdump -i "$iface" -v -c 5 -n not port 22)

        if [[ $? -eq 0 ]]; then
        write-log "RESULTAT COMMAND on dev : "$iface" $command:  " "INFO"

        else 
        write-log "command tcpdump fail with dev "$iface"" "ERROR"

        fi
        done

    else
    write-log "variable interface empty" "ERROR"
    fi
}

function CheckSoft {
    for soft in "${arraysoft[@]}"; do
        checksoft=$(command -v "$soft")
        if [[ -n "$checksoft" ]]; then
            write-log "The Soft : $soft is present on your system" "INFO"
        else
            write-log "The Soft $soft is not installed, installation in progress ..." "INFO"

            DEBIAN_FRONTEND=noninteractive apt update && apt install -y --no-install-recommends "$soft"
            if [[ $? -eq 0 ]]; then
                write-log "Installation of Soft : $soft : done ! " "INFO"
            else
                write-log "Installation of soft : $soft failed " "ERROR"
              fi
        fi
    done

}

function Menu_Diag_Network {
while true; do 
echo -e "\n ------- Diag Network------"
echo "1) Info Network Interfaces"
echo "2) Check Ip Route currently"
echo "3) Check All Interfaces Network Works"
echo "4) TraceRoute"
echo "5) TcpDump"
echo "q) Quit"
read -p "Choice diag network : " network_choice

case $network_choice in 

1)
InfoNetworkInterfaces
;;
2)
iproutes
;;
3)
ethtoolsinterfaces
;;
4)
traceroute
;;
5)
testtcpdump
;;

q|Q) echo "Bye ! have a nice day ^^ "; return 0
;;

esac 
done 
}

HeaderLog
CheckSoft
InfoNetworkInterfaces > /dev/null
Menu_Diag_Network