#!/bin/bash
FileSysctl="/etc/sysctl.conf"
LineIpForward="net.ipv4.ip_forward=1" 


SERVER_IP=""
ETH_INTERFACE=""
CLIENT_PUBLIC_KEY=""
CLIENT_IP=""



pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/Install_Wireguard.log"

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

function UserID {
if [ "$EUID" -ne 0 ];then
	echo "launch the script with privilege root"
	write-log "User not privilges root for launch this script " "ERROR"
	exit
else 
	write-log "User launch script with root privileges" "INFO"

fi 
}


echo "Installation Wireguard "
DEBIAN_FRONTEND=noninteractive apt update && apt install -y --no-install-recommends wireguard-tools 


function CheckConfSysctl {

if grep -q "^#$LineIpForward" "$FileSysctl"; then
	echo "the line "#net.ipv4.ip_forward=1" has been replace by "net.ipv4.ip_forward=1""
	sed -i "s/^#$LineIpForward/$LineIpForward/" "$FileSysctl"
 	write-log "the line "#net.ipv4.ip_forward=1" has been replace by "net.ipv4.ip_forward=1" " "INFO"

elif grep -q "^$LineIpForward" "$FileSysctl";then
	echo "the line already active"
	write-log "the line already active" "INFO"
else
	echo "the line missing, add line in $FileSysctl "
	echo "$LineIpForward" >> "$FileSysctl"
	write-log "the line missing, add line in $FileSysctl " "INFO"
fi
echo "apply right on directories /etc/wireguard"
chmod 077 /etc/wireguard/
write-log "apply right on directories /etc/wireguard" "INFO"

}

function GenerateKeyServer {

write-log  "Generation des clées public et private du server wireguard" "INFO"
wg genkey | tee /etc/wireguard/server-privatekey | wg pubkey > /etc/wireguard/server-publickey

PRIVATE_KEY=$(cat /etc/wireguard/server-privatekey)

read -p "Enter Name Interface Network : " ETH_INTERFACE
read -p "Enter IP address to assign at your server VPN : " SERVER_IP

cat <<EOF > "/etc/wireguard/wg0.conf"
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $SERVER_IP
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $ETH_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -tt nat -D POSTROUTING -o $ETH_INTERFACE -j MASQUERADE
ListenPort = 51820 

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIps = $CLIENT_IP
PersistentKeepalive = 25 
EOF

chmod 600 /etc/wireguard/wg0.conf 
write-log "fichier /etc/wireguard/wg0.conf generated with success !" "INFO"

} 



HeaderLog

UserID
CheckConfSysctl
GenerateKeyServer

EndLog