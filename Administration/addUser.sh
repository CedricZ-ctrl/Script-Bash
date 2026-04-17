#!/bin/bash

pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/addUser.log"

#arry for the function CheckSoft 
arraysoft=("adduser" "getent")
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
    echo "    END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

function Adduser {
	read -p "indique le nom de l utilisateur que tu souhaite retrouver : " name 
	userpresent=$(getent passwd $name)

       if [ -z "$userpresent" ] ; then
	       write-log "the user $name is not present" "INFO"

           while true; do 
           read -p  "the user $name is not present, would you add the $name ? (y/n)" answer
           case $answer in 
           y|Y|yes|Yes)
	       useradd "$name"
           if [[ $? -eq 0 ]]; then 
           write-log "the user $name has been created" "INFO"
           echo "the user $name has been created"
           else 
           write-log "the command adduser failed" "ERROR"
           echo "the command adduser failed"
           fi
           break
           ;;
           n|N|no|No)
	       write-log "you have answer N for added the user  $name " "INFO"
           echo "you have answer N for added the user  $name "
           break
           ;;
           esac 
           done 
       else
	       write-log "the user $name already present" "INFO"
	       echo "user $name already present "
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
HeaderLog
CheckSoft
Adduser
EndLog
