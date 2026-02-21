#!/bin/bash
pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/Check_Disk.log"

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


state=$(df -h / | grep '^/dev/' | tr -s ' ' | cut -d ' ' -f5) 
#tr -s '' permet de supprimer les espaces dans les resultats de df -h 
# cut -d '' permet également de supprimer des espace en trop et -f5 récupéré la valeur de la 5eme colone 
#permet de retirer "%" 
usage=${state%\%}

if [ "$usage" -ge 80 ]; then
	write-log "le disque est quasiement plein : $usage%" "WARNING" 
else
	write-log "le disque est actuellement à $usage%" "INFO"
fi


