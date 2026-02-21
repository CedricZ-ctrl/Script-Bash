#!/bin/bash

pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/Restart_service.log"

services_list=("mysql" "ssh" "smbd")

# pour utiliser la function write-log il faut la syntax suivante:
# write-log "your message" "your event"
#example : write-log " the regex found " "INFO"


SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # On utilise echo directement pour écrire les lignes sans le préfixe Date/INFO
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example : write-log " the regex found " "INFO"
write_log() {
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
    echo "    END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}
check_service () {
	for svc in "${services_list[@]}"; do
		state=$(systemctl is-active "$svc") 

		if [[ "$state" = "active" ]]; then
			write_log "service $svc is running" "INFO"
		else
			 systemctl start "$svc"
			write_log "service  $svc has stopped, start in progress" "INFO"
		fi
	done
}
HeaderLog
check_service 
EndLog
