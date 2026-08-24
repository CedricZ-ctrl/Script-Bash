#!/bin/bash

####################################################################################################################
#                                                                                                                  #
#                       Description Script :                                                                       #
#                                                                                                                  #
# this script change the source location of storage disk principal of VM, for stocked in SSD1To                    #
#                                                                                                                  #
####################################################################################################################

set -euo pipefail

function checkArgs {
    if [ $# -eq 0 ]; then
    write-log "Not Args passed, retry with args please " "ERROR"
    exit 1
    fi
}

function Date {
date '+%Y-%m-%d %H:%M:%S'
}

#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/manage_storage_proxmox.log"

# pour utiliser la function write-log il faut la syntax suivante:
# write-log "your message" "your event"
#example : write-log " the regex found " "INFO"
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

#example : write-log  "the regex found" "INFO"
function write-log {
        local message="$1"
        local event="$2"
        local timestamp=$(Date)
        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

function EndLog {
    local timestamp=$(Date)

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "    END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#$1 argument it's the VMID 
function checkvmidrunning {
    
    vmid=$(qm list | grep "$IDVM"| tr -s ' ' )
    vmidruning=$(qm list | grep "$1" | tr -s ' ' | cut -d ' ' -f4)

    if [ -z "$vmid" ];then 
    write-log "the $IDVM don't no exist" "INFO"
    exit 1

    fi

    statevm=$(echo "$vmid" | cut -d ' ' -f4)

    if [ "$statevm" == "running" ];then 
        qm stop $IDVM
        if [ $? -eq 0 ];then 
        write-log "the VM $IDVM is running and now stopped migration in progress ..." "INFO"
	MigrateStorage
        else 
        write-log "the VM $IDVM not stopped in error occurred in process stop" "ERROR"
        exit 1 
        fi
    else
        write-log "the VM $IDVM is stopped, move storage in progress" "INFO"
        MigrateStorage 
    fi 

}

function MigrateStorage {
    qm disk move "$IDVM" "$SourceDisk" "$Storage" 
    if [ $? -eq 0 ]; then 
    write-log "Migration vmid $IDVM local-lvm to $Storage completed" "INFO"
    else 
    write-log "Migration Failure check log " "ERROR"
    exit 1 
    fi
}


HeaderLog
checkArgs "$@"
IDVM="$1"
SourceDisk=$(qm config $IDVM | grep -E "^(ide|sata|scsi|virtio)[0-9]+"| grep -vE "scsihw" | grep -vE "cloudinit" | grep -vE "media=cdrom" | cut -d ' ' -f1 | tr -d ':')
Storage="SSD1To"

checkvmidrunning "$1" 
EndLog
