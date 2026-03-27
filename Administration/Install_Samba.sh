#!/bin/bash
#================================================================================================================#
#                   Description Script Install_Samba                                                             #
# this script allows installed the service samba for the share file with access user                             #
# the script add user if not present in system, samba need user must be present in system                        #
# Script interactif                                                                                              #
#                                                                                                                #       
#================================================================================================================#

#some command required privileges root
if [ "$EUID" -ne 0 ];then
        echo "launch the script with privilege root"
        exit
fi

# variable used for configuration of samba 
smbconf="/etc/samba/smb.conf"
usersamba=""
sharesamba=""
namedir=""

#arry for the function CheckSoft 
arraysoft=("samba" "date")

#format date for the logs 
function Date {
date '+%Y-%m-%d %H:%M:%S'
}
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/Install_samba.log"

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
function checkstatusFunction {
    local statusfunctionused=$?
    local message=$1
    local level=$2

    if [[ $statusfunctionused -eq 0 ]]; then
    echo "Done ! $message"
    write-log "$message" "INFO"

    else
    echo "Failed !  $message"
    write-log "$message (ExitCode : $statusfunctionused)" "ERROR"

    fi

}

function CreatDirectorySamba {
read -p "Enter the name Path Directory target for creating the Samba share,(example /home/'<user>'/DirectoWorks) : " namedir
mkdir -p "$namedir"
chown "$usersamba":"$usersamba" "$namedir"
chmod 750 "$namedir"
checkstatusFunction "Init Directory Share : $namedir " "INFO"

}

function AddUserSamba {
    read -p "Enter the Name User want add in samba conf : " usersamba
    read -s -p "Enter Password for $usersamba : " passwordsamba
    echo ""
    read -p "Enter a Name for the share samba : " sharesamba

    if ! id "$usersamba" &>/dev/null; then
    echo "add user $usersamba in system is mandatory for samba"
    useradd -m "$usersamba"
    checkstatusFunction "Add Linux User : "$usersamba"" "INFO "
    fi

    if [[ -n "$usersamba" && -n "$passwordsamba" && -n "$sharesamba" ]]; then
    write-log "Information for Added a user and configured the directory share" "INFO"
    echo
    printf "$passwordsamba\n$passwordsamba\n" | smbpasswd -s -a "$usersamba"
    checkstatusFunction "add user $usersamba in smbpasswd " "INFO"
    else
    write-log "missing information in function AddUserSamba" "ERROR"
    exit 1
    fi

}

function confsamba {
cat <<EOF >> "$smbconf"
[$sharesamba]
comment = Directory Scripts training
path = $namedir
browseable = yes
read only = no
valid users = $usersamba
guest ok = no
EOF
checkstatusFunction "configuration $smbconf" "INFO"
systemctl restart smbd.service
checkstatusFunction "service smbd restarted " "INFO"
}


HeaderLog
CheckSoft
if [[ -f "$smbconf" ]]; then
AddUserSamba
CreatDirectorySamba
confsamba
else
echo "$smbconf don't exist"
write-log "$smbconf don't exist with error : $_ " "ERROR"
fi

EndLog
