#!/bin/bash
pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/Check_openPorts.log"

# write-log "your message" "your event"
#example : write-log " the regex found " "INFO"

write-log() {
        local message="$1"
        local event="$2"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi


        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

declare -a ports=("22" "80" "443")

while read -r line; do

	if [[ "$line" =~ :([0-9]+)$ ]]; then
		port="${BASH_REMATCH[1]}"
		ports+=("$port")
	fi

done < <(ss -tuln)

for p in "${ports[@]}"; do
	case $p in 
		22) svc="SSH" ;;
		80) svc="HTTP" ;;
		443) svc="HTTPS" ;;
		*) svc="Unknow" ;;
	esac

	write-log "port $p ($svc) is open" "INFO"
done
