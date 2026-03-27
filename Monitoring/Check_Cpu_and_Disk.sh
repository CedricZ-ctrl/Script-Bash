#!/bin/bash
#================================================================================================================#
#                   Description Script Check_Cpu_and_Disk.sh                                                 #
# this script allows you to perfoma an initial diagnostic on:                                                    #
# CPU,DISK,
#                                                                                                                #       
#================================================================================================================#

#some command required access privilege root 
if [ "$EUID" -ne 0 ];then
        echo "launch the script with privilege root"
        exit
fi

#arry for the function CheckSoft 
arraysoft=("stress-ng" "smartmontools")
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
function Date {
    date '+%Y-%m-%d %H:%M:%S'
}
pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/CheckCpuRamDisk.log"

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


function StressCPU {

    dircpu="/proc/cpuinfo"
    cpuinfo=$(grep -c "^processor" "$dircpu")

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
CheckSoft
MenuDiagSystem
