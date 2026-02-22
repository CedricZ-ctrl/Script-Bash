#!/bin/bash

#================================================================================================================#
#         CONFIGURATION LOGS                                                                                     #
#================================================================================================================#
pathdirlog="/home/bandit/Scripts/Logs"
pathfilelog="$pathdirlog/ScriptManagementHyperviser.log"

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

SEPARATOR="============================================================="

function HeaderLog {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "START SCRIPT: $(basename "$0")" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
    echo "Date : $timestamp" >> "$pathfilelog"
    echo "$SEPARATOR" >> "$pathfilelog"
}

#example to use : write-log  "the regex found" "INFO"
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
# 'trap' here ensure endlog function run if the script exits unexpectedly or when the user enters q | Q to quit.
trap EndLog EXIT INT 
#===================================================================================================================================================#

function SetupConnection {

    echo -e "Set Ip Hyperviser target"
PVE_IP=$(CheckString "Enter IP or Domain Name Server Proxmox :")
PVE_USER=$(CheckString "Enter Username Proxmox : ")
ESXI_IP=$(CheckString "Enter IP or Domaine Name Server ESXI : ")
ESXI_USER=$(CheckString "Enter Username Esxi : ")

if [[ -n "$PVE_IP" ]] &&  [[ -n "$PVE_USER" ]]; then
write-log "ip proxmox set : $PVE_IP with username $PVE_USER" "INFO"
Menu_Proxmox

fi

if [[ -n "$ESXI_IP" ]] && [[ -n "$ESXI_USER" ]]; then 
write-log "ip esxi set : $ESXI_IP with username $ESXI_USER " "INFO"
Menu_ESXI
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


#===========================================================================================================#
#                           PART ESXI                                                                       #
#===========================================================================================================#

function Menu_ESXI {
    while true; do
    echo -e "\n----- ESXI MENU -----"
    echo "1) List VMs"
    echo "2) Start,Restart Or Stopped VMs ? "
    echo "3) Network "
    echo "4) Snapshots"
    echo "5) Manage Users ESXI"
    echo "q) Quit"
    read -p "ESXI choice : " esxi_choice

    case $esxi_choice in 

    1)
    ListVMESXI
    ;;

    2) 
    StartStopOrRebootVMESX
    ;;

    3)
    SubMenu_Network
    ;;

    4)
    Manage_Snapshot
    ;;

    5)
    SubMenu_UserEsxi
    ;;
    q|Q) echo "Bye ! Have a nice day ^^"; return 0 ;;

    esac 
    done

}

function ListVMESXI {
    #"The ; act as commands given and move to the next one. For example, the shell runs this command first: vim-cmd vmsvc/getallvms, then moves to the next one ;, and so on. The echo "" is used to create a space."
    result=$(ssh "$ESXI_USER@$ESXI_IP" "vim-cmd vmsvc/getallvms; echo''; echo 'VM ACTIF: '; esxcli network vm list")
    write-log "Action List VMs in ESXI : $result" "INFO"
    echo "$result"
}
function StartStopOrRebootVMESX {
    choice=$(CheckString "you want start, stop or reboot vm ? ")
    vmid=$(CheckNumber "Enter the vmid to $choice ")

    if [[ "$choice" == "start" ]]; then
    cmd="power.on"
    elif [[ "$choice" == "stop" ]]; then
    cmd="power.off"
    elif [[ "$choice" == "reboot" ]]; then
    cmd="power.reboot"
    fi
    echo "Run "$choice" on vm $vmid "
    result=$(ssh "$ESXI_USER@$ESXI_IP" "vim-cmd vmsvc/$cmd $vmid ")
    write-log "Action "$choice" in ESXI on VM "$vmid" : $result" "INFO"
    echo "$result"
}

function SubMenu_Network {
    while true; do
    echo -e "\n----- ESXI MENU Network-----"
    echo "1) Checking NIC, VSwitch, Portgroup"
    echo "2) Create PortGroup or Delete Portgroup "
    echo "q) Quit"
    read -p "ESXI choice : " esxi_choice

    case $esxi_choice in 
    
    1)
    CheckNetworking
    ;;

    2)  
    ManagePortGroupESXI
    ;;

    q|Q) echo "Bye ! Have a nice day ^^"; return 0 ;;

    esac
    done
}

function CheckNetworking {
    choice=$(CheckString  "you want check what ? NIC, VSwitch, Portgroup : ")

    if [[ "$choice" == "NIC" ]]; then
    cmd_network="esxcli network nic list"

    elif [[ "$choice" == "VSwitch" ]]; then
    cmd_network="esxcli network vswitch standard list" 
     
    elif [[ "$choice" == "Portgroup" ]]; then
    cmd_network="esxcli network vswitch standard portgroup list"
    fi
    echo "Get $choice"
    result=$(ssh "$ESXI_USER@$ESXI_IP" "$cmd_network")
    write-log "Action in ESXI Network $choice " "INFO"
    echo "$result"
}

function ManagePortGroupESXI {
    choice_portgroup=$(CheckString "You want Create New Portgroup ? or Delete a Portgroup ? (specify: "Create" or "Delete"): ")

    if [[ "$choice_portgroup" == "Create" ]]; then
    CreatePortGroup
    elif [[ "$choice_portgroup" == "Delete" ]]; then
    DeletePortGroup
    fi
}


function CreatePortGroup {
    name_portgroup=$(CheckString "Give me the name for the new portgroup please ? :" )
    choice_vswitch=$(CheckString "Which VSwitch do you want  to add the $name_portgroup ? (vSwitch0, vSwitch1) ")
    result=$(ssh "$ESXI_USER@$ESXI_IP" "esxcli network vswitch standard portgroup add --portgroup-name='$name_portgroup' --vswitch-name='$choice_vswitch'")
    write-log "Action in ESXI Network creating $name_portgroup in $choice_vswitch" "INFO"
    echo "$result"
}


function DeletePortGroup {
    name_portgroup=$(CheckString "Give me the name for the Delete the portgroup please ? : ")
    choice_vswitch=$(CheckString "Which VSwitch do you want delete the $name_portgroup ? (vSwitch0, vSwitch1) ")
    result=$(ssh "$ESXI_USER@$ESXI_IP" "esxcli network vswitch standard portgroup remove --portgroup-name='$name_portgroup' --vswitch-name='$choice_vswitch'")
    write-log "Action in ESXI Network deleting $name_portgroup in $choice_vswitch" "INFO"
    echo "$result"
}


function Manage_Snapshot {
    

    choice=$(CheckString "you want get info snapshot (get) ? you want create snapshot (create) ? remove (remove) ? or revert (revert) snapshot ? ")
    vmid=$(CheckNumber "Enter the vmid to $choice ")

    if [[ $choice == "get" ]]; then
    cmd="snapshot.get"
    
    elif [[ "$choice" == "create" ]]; then
    cmd="snapshot.create"
    name_snapshot=$(CheckString "name for the new snapshot : ") 

    elif [[ "$choice" == "remove" ]]; then
    cmd="snapshot.remove"
    name_snapshot=$(CheckNumber "give me ID snapshot you want delete : ")

    elif [[ "$choice" == "revert" ]]; then
    cmd="snapshot.revert"
    supprespowerON="1"
    name_snapshot=$(CheckNumber "give me ID snapshot you want revert : ")

    fi
    echo "Run $choice Snapshot on vm $vmid "
    result=$(ssh "$ESXI_USER@$ESXI_IP" "vim-cmd vmsvc/$cmd $vmid $name_snapshot $supprespowerON")
    write-log "Action $choice in ESXI : $result " "INFO"
}
function SubMenu_UserEsxi {
       while true; do
    echo -e "\n----- ESXI Menu Manage User/Permissions-----"
    echo "1) Manage User Host Esxi (list,add,set)"
    echo "2) Permissions Users Esxi"
    echo "q) Quit"
    read -p "ESXI choice : " esxi_choice

    case $esxi_choice in 
    
    1)
    Manage_UsersHost_ESXI
    ;;

    2) 
    PermissionsUserHost_ESXI
    ;;

    q|Q) echo "Bye ! Have a nice day ^^"; exit 0;;

    esac 
    done 


}

function  Manage_UsersHost_ESXI {
    choice=$(CheckString "What do you want in Host ESXI account ? : (list,add,remove or set) ")

    if [[ $choice == "list" ]]; then
    cmd="list"
    
    elif [[ "$choice" == "add" ]]; then
    name_account=$(CheckString "Set Username : ") 
    echo -n "Set Password : "
    read -s Psswd_account 
    cmd="add -d $name_account -i $name_account -p $Psswd_account -c $Psswd_account"
    

    elif [[ "$choice" == "remove" ]]; then
    name_account=$(CheckString "specify the user to delete  : ") 
    cmd="remove -i $name_account "
    

    elif [[ "$choice" == "set" ]]; then
    option=$(CheckString "You want set password ? modify Username ? Shell access ? : ")

    if [[ "$option" == "password" ]]; then 
    name_account=$(CheckString "specifiy  Username to modify : ")
    echo -n "Set New Password : "
    read -s Psswd_account 
    cmd="set -i $name_account -p $Psswd_account -c $Psswd_account"

    elif [[ "$option" == "Username" ]]; then
    name_account=$(CheckString "Set New Username : ") 
    cmd="set -i $name_account"

    elif [[ "$option" == "Shell access" ]]; then
    shellaccess=$(CheckString "shell access true or false ? :")
    cmd="set -s $shellaccess"
    fi

    fi
    echo "Run $choice account : " 
    result=$(ssh "$ESXI_USER@$ESXI_IP" "esxcli system account $cmd")
    echo "$result"
    write-log "Action $choice in ESXI : $result " "INFO"


}

function PermissionsUserHost_ESXI {
    choice=$(CheckString "What do you want in Host ESXI Permission ? : (list,set,unset) ")

    if [[ $choice == "list" ]]; then
    cmd="list"

    elif [[ "$choice" == "set" ]]; then
    option=$(CheckString "You want set permission (specify set) ? unset permission (specify unset) ? : ")

    if [[ "$option" == "set" ]]; then 
    name_account=$(CheckString "specifiy  Username to set permission : ")
    name_role=$(CheckString "Specify role for the $name_account : (Admin,NoAccess,ReadOnly) ")
    cmd="set -i $name_account -r $name_role"

    elif [[ "$option" == "Unset" ]]; then
    name_account=$(CheckString "Set Username to unset : ") 
    cmd="unset -i $name_account"
    fi

    fi
    echo "Run $choice account : " 
    result=$(ssh "$ESXI_USER@$ESXI_IP" "esxcli system permission $cmd")
    echo "$result"
    write-log "Action $choice in ESXI : $result " "INFO"
}

function Menu_principal {

    while true; do
    echo -e "\n------ Menu Principal -----"
    echo "1) Menu Proxmox"
    echo "2) Menu ESXI "
    echo "q) Quit"
    read -p "Your Choice ? : " menu_choice

    case $menu_choice in 

    1)
    Menu_Proxmox
    ;;

    2) 
    Menu_ESXI
    ;;

    q|Q) echo "Bye ! Have a nice day ^^"; exit 0 ;;
    
    esac
    done
}


HeaderLog
SetupConnection


