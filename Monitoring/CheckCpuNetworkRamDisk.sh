#!/bin/bash
# set -o pipefail, force the pipeline return the exitcode  of the first command example for : "result=$({ df -h $filesystem | tr -s ' ' | cut -d ' ' -f5,6 | tail -1; } 2>&1)" the set -o pipefail will get the resultat of "df -h" instead of tail -1
set -o pipefail
datetoday=$(date | tr -s ' ' | cut -d ' ' -f1-4)

if [ "$EUID" -ne 0 ];then
        echo "launch the script with privilege root"
        exit
fi
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="$HOME/Scripts/Script Linux/Monitoring/Logs"
pathfilelog="$pathdirlog/CheckCpuRamDisk.log"

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
function write-log {
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


function StressCPU {

    dircpu="/proc/cpuinfo"
    cpuinfo=$(grep -c "^processor" "$dircpu")

    toolstress=$(command -v stress-ng)
    if [[ -n "$toolstress" ]]; then
    write-log "Tools stress-ng already present" "INFO"
    else
    DEBIAN_FRONTEND=noninteractive apt update && apt install -y --no-install-recommends stress-ng
    write-log "tools stress-ng not present in system, installation DONE" "INFO"
    fi

    if [[ -n "$cpuinfo" ]]; then
    command0=$(stress-ng --metrics-brief --timeout 60s --cpu "$cpuinfo" --io "$cpuinfo" --aggressive --ignite-cpu --maximize --pathological 2>&1)
   
        if [[ $? -eq 0 ]]; then 
        echo "$command0"
        write-log " $command0 : " "INFO"
        else
        echo "stress-ng command fail ! " "ERROR"
        fi
    else 
    echo "get information cpu no works " "ERROR"
    fi 
}

function SmartDisk {

    diskinfo=$(lsblk -dn -o NAME | grep -E "^(sd|nvme)")
    arraydisk=()
    if [[ -n "$diskinfo" ]]; then
        mapfile -t arraydisk <<< "$diskinfo"

        for disk in "${arraydisk[@]}"; do
            resultat=$(smartctl -a /dev/$disk)
            echo "Resultat for the disk "$disk" : $resultat"
            write-log "Resultat for the disk "$disk" : $resultat" "INFO"
        done
    else
    write-log "Variable diskinfo empty !" "ERROR"
    fi

}

function MenuDiagSystem {

    while true; do 
    echo -e "\n----------Menu Diag System---------"
    echo "1) Stress CPU"
    echo "2) SmartDisk "
    echo "q|Q) Quit "
    read -p "Choice DiagSystem : " choice

    case $choice in 

    1)
    StressCPU
    ;;
    2)
    SmartDisk
    ;;

    q|Q) echo "Bye ! have a nice day ^^ "; return 0 
    ;;

    esac
    done 
}
HeaderLog
MenuDiagSystem
