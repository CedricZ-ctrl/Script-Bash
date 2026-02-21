#!/bin/bash
# set -o pipefail, force the pipeline return the exitcode  of the first command example for : "result=$({ df -h $filesystem | tr -s ' ' | cut -d ' ' -f5,6 | tail -1; } 2>&1)" the set -o pipefail will get the resultat of "df -h" instead of tail -1
set -o pipefail
datetoday=$(date | tr -s ' ' | cut -d ' ' -f1-4)
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/home/bandit/Scripts/Script Linux/Monitoring/Logs"
pathfilelog="$pathdirlog/Check_System.log"

SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example to use : write-log  "the regex found" "INFO"
write-log() {
        local message="$1"
        local event="$2"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi
        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

function EndLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}
# 'trap' here ensure endlog function run if the script exits unexpectedly or when the user enters q | Q to quit.
trap EndLog EXIT INT 

function LoadAvg {
    result=$({ uptime | tr -s ' ' | cut -d ' ' -f10-14; } 2>&1)
    if [[ $? -eq 0 ]]; then
    write-log "1min,5min,15min : $result" "INFO"
    else 
    write-log "the uptime command, did not work Exitcode : $result " "ERROR"
    return 1
    fi

    start=$({ uptime -p | tr -s ' ' | cut -d ' ' -f1-7; } 2>&1)
    if [[ $? -eq 0 ]]; then
    write-log "$start" "INFO"
    return 0
    else
    write-log "the uptime -p command did not work : Exitcode : $start" "ERROR"
    return 1
    fi

}

function StateRam {
    result=$({ free -h | tr -s ' ' | grep "Mem:" | cut -d ' ' -f2-4; } 2>&1)
    if [[ $? -eq 0 ]]; then
    write-log "Ram : total,used,free -> $result" "INFO"
    return 0
    else 
    write-log "the free memory RAM command, did not work : Exitcode : $result " "ERROR"
    return 1
    fi
}

function StateDisk {
    df -h | tr -s ' ' | cut -d ' ' -f1

    read -p "Enter Partition you want to check : " filesystem

    result=$({ df -h $filesystem | tr -s ' ' | cut -d ' ' -f5,6 | tail -1; } 2>&1)
    if [[ $? -eq 0 ]]; then
    read -r used mount <<< "$result"
    write-log "Space Disk  used in $filesystem is busy at $used and Mounted on $mount" "INFO"
    return 0 
    else
    write-log "the df -h command did not work: Exitcode : $result" "ERROR"
    return 1
    fi
}

function CheckNetwork {
    accessnet=$( ping -c4 -q 8.8.8.8 | tail -2 )
    if [[ $? -eq 0 ]]; then
    write-log "the check ping $accessnet " "INFO"
    else
    write-log "the check ping failed " "ERROR"
    fi

    resolvname=$({ nslookup google.com | grep "Address" |  grep --invert-match "#";} 2>&1 )
    if [[ $? -eq 0 ]]; then
    write-log "resolve domain name google.com : $resolvname " "INFO"
    else 
    write-log "resolve domain name failed : $resolvname" "ERROR"
    fi 

    read -p "Enter interface network you want check : " eth
    if ip link show "$eth" > /dev/null 2>&1; then

    rx=$({ ip -s link show $eth | grep -A 1 "RX:" | tail -1 | tr -s ' ' | cut -d ' ' -f2; } 2>&1 )
    tx=$({ ip -s link show $eth | grep -A 1 "TX:" | tail -1 | tr -s ' ' | cut -d ' ' -f2; } 2>&1 )

    rx_mo=$(( rx / 1024 / 1024 ))
    tx_mo=$(( tx / 1024 / 1024 ))

    write-log "the interface $eth -> receipt: ${rx_mo}Mo and send: ${tx_mo}Mo in date $datetoday " "INFO"
    else
    write-log "the check interface static $eth  does not exist " "ERROR"
    return 1
    fi
}

function CheckSystem {
LoadAvg
if [[ ! $? -eq 0 ]]; then
write-log "The function LoadAvg Failed" "ERROR"
fi 

StateRam
if [[ ! $? -eq 0 ]]; then
write-log "The function StateRam Failed" "ERROR"
fi

StateDisk
if [[ ! $? -eq 0 ]]; then
write-log "The function StateDisk Failed" "ERROR"
fi

CheckNetwork
if [[ ! $? -eq 0 ]]; then
write-log "The function CheckNetwork Failed" "ERROR"
fi

}


HeaderLog
CheckSystem

