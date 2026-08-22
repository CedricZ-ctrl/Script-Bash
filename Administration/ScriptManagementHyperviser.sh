#!/bin/bash
#================================================================================================================#
#                   Description Script Restart_service                                                           #
# WARNING: you need setup you key ssh in each hypervisor before run this script                                  #
#                                                                                                                #   
# this script allows managed your Hypervisor Proxmox  or both at the same time                           	 #                             
#  you can manage for each hypervisor: VMProxmox,snapshot,users,containers LXC,Network  			 #
#														 #
#                                                                                                                #
#														 #	
#================================================================================================================#

#format date for the logs 
function Date {
date '+%Y-%m-%d %H:%M:%S'
}
#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/var/log/Logs_script_personnal"
pathfilelog="$pathdirlog/ScriptManagementHyperviser.log"

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
    echo "    END SCRIPT" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}
# 'trap' here ensure endlog function run if the script exits unexpectedly or when the user enters q | Q to quit.
trap EndLog EXIT INT 
#===================================================================================================================================================#

function CheckNumber {
    local prompt_message="$1"  
    local input                
    while true; do             
        read -p "$prompt_message" input 
        if [[ "$input" =~ ^[0-9]+$ ]]; then 
            echo "$input"      
            return 0           
        else
            echo -e "Erreur : give me number, not characters." >&2
            write-log "Characters were entered, which caused an error." "ERROR"
        fi
    done

}

function CheckString {
    local prompt_message="$1" 
    local input               
    while true; do            
        read -p "$prompt_message" input
        if [[ "$input" =~ ^[a-zA-Z0-9._-]*$ ]]; then 
            echo "$input"
            return 0
        else
            echo -e "Erreur : give me characters, not number." >&2
            write-log "Numbers were entered, which caused an error. " "ERROR"
        fi
    done
}

function SetupConnection {

    echo -e "Set Ip Hyperviser target"
PVE_IP=$(CheckString "Enter IP or Domain Name Server Proxmox :")
PVE_USER=$(CheckString "Enter Username Proxmox : ")

if [[ -n "$PVE_IP" ]] &&  [[ -n "$PVE_USER" ]]; then
write-log "ip proxmox set : $PVE_IP with username $PVE_USER" "INFO"
Menu_Proxmox

fi
}

function Menu_Proxmox {
    while true; do 
    echo -e "\n----- PROXMOX MENU -----"
    echo "1) List Vms"
    echo "2) List LXC"
    echo "3) Start,Restart Or Stopped VMs ? "
    echo "4) Start,Restart Or Stopped LXC ? "
    echo "5) Network "
    echo "q) Quit"
    read -p "Proxmox choice : " proxmox_choice

    case $proxmox_choice in 
    1)
    ListVMProxmox
    ;;

    2) 
    ListLXCProxmox
    ;;

    3)
    StartStopOrRebootVMProxmox
    ;;

    4) 
    LXCStartRebootRemoveProxmox
    ;;

    5) 
    SubMenu_Network_Proxmox
    ;;

    q|Q) echo "Bye ! Have a nice day ^^"; return 0 ;;

    esac 
    done   
}
function ListLXCProxmox {
    result=$(ssh "$PVE_USER@$PVE_IP" "pct list")
    write-log "Action List LXC in Proxmox : $result" "INFO"
    echo "$result"
}
function ListVMProxmox {
    result=$(ssh "$PVE_USER@$PVE_IP" "qm list")
    write-log "Action List VMs in Proxmox : $result " "INFO"
    echo "$result"
}

function StartStopOrRebootVMProxmox {
    local choice=$(CheckString "you want : Start ? Stop ? or Reboot ?: ")
    local vmid=$(CheckNumber "Enter the vmid target: ")
    local cmd=""

    case "$choice" in

    "Start")
    cmd="start"
    write-log "Choice $choice" "INFO"
    ;;

    "Stop")
    cmd="stop"
    write-log "Choice $choice" "INFO"
    ;;

    "Reboot")
    cmd="reboot"
    write-log "Choice $choice" "INFO"
    ;;

    *) 
    echo "choice invalid, among Start,Stop or Reboot "
    write-log "Choice Invalid, : $choice" "INFO"
    ;;
    esac 

    write-log "Run $choice on VM ID : $vmid " "INFO"
    result=$(ssh "$PVE_USER@$PVE_IP" "qm $cmd $vmid")

    status_ssh=$?

    if [[ $status_ssh == 0 ]];then
    write-log "Action $choice in PROXMOX on VM $vmid : ExitCode : $status_ssh " "SUCCES"
    else 
    write-log "Action $choice in PROXMOX on VM $vmid : ExitCode : $status_ssh " "ERROR"
    fi 
    echo "$choice VM $vmid = Exitcode: $status_ssh"
}

function LXCStartRebootRemoveProxmox {

    local choice=$(CheckString "you want Start, Stop or Reboot LXC ?: ")
    local vmid=$(CheckNumber "Enter the lxc target : ")
    local cmd=""

    case "$choice" in

    "Start")
    cmd="start"
    write-log "Choice $choice" "INFO"
    ;;

    "Stop")
    cmd="stop"
    write-log "Choice $choice" "INFO"
    ;;

    "Reboot")
    cmd="reboot"
    write-log "Choice $choice" "INFO"
    ;;

    *) 
    echo "choice invalid, among Start,Stop or Reboot "
    write-log "Choice Invalid, : $choice" "INFO"
    ;;
    esac 

    echo "Run $choice in LXC ID :  $vmid "
    result=$(ssh "$PVE_USER@$PVE_IP" "pct $cmd $vmid")

    status_ssh=$?

    if [[ $status_ssh == 0 ]];then
    write-log "Action $choice in PROXMOX on LXC $vmid : ExitCode : $status_ssh " "SUCCES"
    else 
    write-log "Action $choice in PROXMOX on LXC $vmid : ExitCode : $status_ssh " "ERROR"
    fi 

    echo "$choice LXC $vmid = ExitCode: $status_ssh"
}

function SubMenu_Network_Proxmox {
    while true; do
    echo -e "\n----- PROXMOX MENU Network-----"
    echo "1) Checking Interfaces"
    echo "2) Add,Modify or Remove interfaces"
    echo "q) Quit"
    read -p "PROXMOX choice : " proxmox_choice

    case $proxmox_choice in 
    
    1)
    CheckInterfaceNetworkProxmox
    ;;

    2)
    AddModifyRemoveInterfacesProxmox
    ;;

    q|Q) echo "Bye ! Have a nice day ^^"; return 0 ;;

    esac
    done
}

function CheckInterfaceNetworkProxmox {
    result=$(ssh "$PVE_USER@$PVE_IP" "cat /etc/network/interfaces")
    write-log "Action List Interface Netwok in Proxmox : $result " "INFO"
    status_ssh=$?
    echo "$result exitcode : $status_ssh"
}

function AddModifyRemoveInterfacesProxmox {
    choice=$(CheckString "you want Added or Remove interfaces network ?: ")
    write-log "choice $choice interface network " "INFO"

    if [[ "$choice" == "Added" ]]; then
    AddInterfacesNetworkProxmox

    elif [[ "$choice" == "Remove" ]]; then
    RemoveInterfacesNetworkProxmox

    fi
}
function AddInterfacesNetworkProxmox {
    iface=$(CheckString "Enter Name Iface : ")
    read -p "Enter IPAdress, at format ( example : 192.168.1.0/24) :" address
    read -p "Enter Gateway at format (example : 192.168.1.254) :" gateway

    #conf bridge default 
    bridgedefault="bridge-ports none\\n\\tbridge-stp off\\n\\tbridge-fd 0"

    # check, if IFACE is already present 
    ssh "$PVE_USER@$PVE_IP" "grep -q 'iface $iface' /etc/network/interfaces"

    if [[ $? -eq 0 ]]; then 
    echo "the iface : $iface already present ! "
    write-log "the iface : $iface already present ! " "INFO"
    else 
    ssh "$PVE_USER@$PVE_IP" "sed -i '/^source \/etc\/network\/interfaces.*/i auto $iface\\niface $iface inet static \\n\\taddress $address\\n\\tgateway $gateway\\n\\t$bridgedefault\\n' /etc/network/interfaces"
    
    if [[ $? == 0 ]]; then 
    write-log "Add iface $iface in proxmox interfaces network with ip_address: $address and the gateway: $gateway " "INFO"
    echo "Add iface $iface in proxmox interfaces network"
    else 
    write-log "error in function AddInterfacesNetworkProxmox : $_ " "Error"
    echo "error in function AddInterfacesNetworkProxmox : $_ "
    fi 
    fi
}

function RemoveInterfacesNetworkProxmox {
    iface=$(CheckString "Enter Name Iface to Remove : ")
    result=$(ssh "$PVE_USER@$PVE_IP" "sed -i '/auto $iface/,/bridge-fd 0/d' /etc/network/interfaces")
    if [[ $? == 0 ]]; then 
    write-log "remove iface $iface in proxmox interfaces network " "INFO"
    echo "remove iface $iface in proxmox interfaces network"
    else 
    write-log "error in function RemoveInterfacesNetworkProxmox : $_ " "Error"
    echo "error in function RemoveInterfacesNetworkProxmox : $_ "
    fi 
}

HeaderLog
SetupConnection
EndLog

