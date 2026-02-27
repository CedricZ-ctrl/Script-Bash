#!/bin/bash

pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/Restart_service.log"

services_list=()

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
function write_log {
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


function check_service {

    read -p "Enter the different(s) services, you want managed : " -a services_list
    write_log "List of services :  ${services_list[*]}." "INFO"

	for svc in "${services_list[@]}"; do
		service_active=$(systemctl is-active "$svc" 2>&1) 
		if [[ "$service_active" == "active" ]]; then
			write_log "service $svc is running." "INFO"
		else
            write_log "Service $svc stopped." "INFO"
			sudo systemctl start "$svc"
            if [[ $? -eq 0 ]]; then 
            write_log "the $svc has been started. " "INFO"
            else 
            write_log "started failed for $svc : Exitcode : $service_active" "ERROR"
            fi
		fi

        service_enabled=$(systemctl is-enabled "$svc" 2>&1)
        if [[ "$service_enabled" == "disabled" ]]; then 
            write_log "Service $svc is $service_enabled, next boot the $svc don't running. enabling in progress...." "WARNING"
            sudo systemctl enable $svc
            if [[ $? -eq 0 ]]; then 
            write_log "the $svc has been enable. " "INFO"
            else 
            write_log "enable failed for $svc : Exitcode : $service_enabled" "ERROR"
            fi
        elif [[ "$service_enabled" == "enabled" ]]; then 
            write_log "Service $svc is already enable. " "INFO"
        else 
            write_log "Service $svc status is : $service_enabled." "INFO"
        fi
	done
}
HeaderLog
check_service 
EndLog
