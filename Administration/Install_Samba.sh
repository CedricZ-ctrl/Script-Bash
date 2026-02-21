#!/bin/bash

if [ "$EUID" -ne 0 ];then
        echo "launch the script with privilege root"
        exit
fi

smbconf="/etc/samba/smb.conf"
usersamba=""
sharesamba=""
namedir=""

pathdirlog="/home/bandit/Logs"
pathfilelog="$pathdirlog/Install_samba.log"

# pour utiliser la function write-log il faut la syntax suivante:
# write-log "your message" "your event"
#example : write-log " the regex found " "INFO"
SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ ! -d "$pathdirlog" ];then
                mkdir -p "$pathdirlog"
        fi

    # On utilise echo directement pour écrire les lignes sans le préfixe Date/INFO
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example : write-log  "the regex found" "INFO"
write-log() {
        local message="$1"
        local event="$2"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp [$event] - $message" >> "$pathfilelog"
}

function EndLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$SEPARATOR" >> "$pathfilelog"
    echo "    END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
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

function CheckSambaispresent {
sambaispresent=$(dpkg -l samba)
if [[ -n "$sambaispresent" ]]; then
echo "Samba is already present go next step "
write-log "Samba is already present go next step" "INFO"
else

echo "Installation Samba && configuration Directory Samba "
DEBIAN_FRONTEND=noninteractive apt update && apt install -y --no-install-recommends samba
checkstatusFunction "Installation of Samba" "INFO"
write-log "Samba not present on system, installation Done"

fi
}


function CreatDirectorySamba {
read -p "Enter the name Path Directory target for creating the Samba share,(example /home/'<user>'/DirectoWorks) : " namedir
mkdir -p $namedir
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
    checkstatusFunction "Add Linux User " "INFO "
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
CheckSambaispresent
if [[ -f "$smbconf" ]]; then
CreatDirectorySamba
AddUserSamba
confsamba
else
echo "$smbconf don't exist"
write-log "$smbconf don't exist with error : $_ " "ERROR"
fi

EndLog
