# ~/.bash.d/.cp.bash
#########################################################################
# >>>   .cp.bash                                                        #
#-----------------------------------------------------------------------#
# Helper functions to setup config on a new linux host with ssh access  #
#########################################################################
#!/bin/bash

# COLOURING VARIABLES / ALIASES
RED='\033[0;31m'
B_RED='\033[1;91m'
GREEN='\033[0;32m'
B_GREEN='\033[1;92m'
CYAN='\033[0;96m'
B_CYAN='\033[1;96m'
YELLOW='\033[0;33m'
B_YELLOW='\033[1;33m'
WHITE='\033[0;37m'
B_WHITE='\033[1;97m'
NC='\033[0m' #No Colour

readInHostIdArrays() {
	local vbose=false
	
	while getopts ":v" opt; do
		case $opt in
		v) 	vbose=true 
			;;
		\?)	echo "Invalid option: -${OPTARG}" >&2; return 1 
			;;
		esac
	done
	
	XIFS="$IFS" # Set IFS to temp var for restoring later
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'all=($(cat $HOME/.bash.d/.iphosts))' # array of hosts by ip addresses
	IFS="$XIFS" # Restore IFS back

	for hoststring in ${all[@]}; do
		XIFS="$IFS" # Set IFS to temp var for restoring later
      
		IFS=':' read -a iporthostarr <<< "$hoststring"
		
		iuserhost="${iporthostarr[0]}"
		iport="${iporthostarr[1]}"
		iname="${iporthostarr[2]}"

		eval $iname[0]="$hoststring" # array of hosts by ip addresses
		
		if [[ "$vbose" = true ]]; then
			eval expandedarr=\${${iname}[@]}
			echo "single element array declared: \"$iname\" --> calling: \"\${$iname[@]}\" = \"$expandedarr\""
		fi

		IFS="$XIFS" # Restore IFS back
	done
}

castfile() {
  if [[ $# -gt 1 ]]; then

    b_var="$1"
    bcast_set="${b_var}[@]"

    file_to_send="$2"    
    target_path="~"
    if [ -n "$3" ]; then
      target_path="${@:3}"
    fi
    
    XIFS="$IFS" # Set IFS to temp var for restoring later

    for iporthost in ${!bcast_set}; do
      IFS=':' read -a iporthostarr <<< "$iporthost"
      iuserhost="${iporthostarr[0]}"
      iport="${iporthostarr[1]}"

      IFS='@' read -a iuserhostarr <<< "$iuserhost"
      iuser="${iuserhostarr[0]}"
      ihost="${iuserhostarr[1]}"
      
      if [ -f "$file_to_send" ]; then
        scp -P "$iport" "$file_to_send" "$iuser@$ihost":"$target_path"
      elif [ -d "$file_to_send" ]; then
        scp -r -P "$iport" "$file_to_send" "$iuser@$ihost":"$target_path/"
      else
        echo -e "[castfile] Usage::\ncastfile <broadcast_set> <local_file_or_dir> <target_path>" >&2; return 1
      fi
    done

    IFS="$XIFS" # Restore IFS back

  else
    echo -e "[castfile] Usage::\ncastfile <broadcast_set> <local_file_or_dir> <target_path>" >&2; return 1
  fi
}

execcmd(){
  if [[ $# -gt 1 ]]; then

    b_var="$1"
    b_var_indirect_array="hostset$b_var[@]"
    bcast_set="${!b_var_indirect_array}"

    cmd_to_send="${@:2}"

    XIFS="$IFS" # Set IFS to temp var for restoring later

    for iporthost in ${bcast_set}
    do
      IFS=':' read -a iporthostarr <<< "$iporthost"
      iuserhost="${iporthostarr[0]}"
      iport="${iporthostarr[1]}"

      IFS='@' read -a iuserhostarr <<< "$iuserhost"
      iuser="${iuserhostarr[0]}"
      ihost="${iuserhostarr[1]}"

      ssh -p "$iport" "iuser"@"$ihost" "screen -d -m $cmd_to_send";
    done

    IFS="$XIFS" # Restore IFS back

  else
    echo -e "[execcmd] Usage::\nexeccmd <broadcast_set> reboot\nbroadcast_set values: all"
  fi
}

echocmd() {
  if [[ $# -gt 1 ]]; then

    b_var="$1"    
    bcast_set="${b_var}[@]"

    cmd_to_send="${@:2}"

    XIFS="$IFS" # Set IFS to temp var for restoring later

    for iporthost in ${!bcast_set}
    do
      IFS=':' read -a iporthostarr <<< "$iporthost"
      iuserhost="${iporthostarr[0]}"
      iport="${iporthostarr[1]}"
      iname="${iporthostarr[2]}"

      IFS='@' read -a iuserhostarr <<< "$iuserhost"
      iuser="${iuserhostarr[0]}"
      ihost="${iuserhostarr[1]}"

      echo -e "\n${B_CYAN}${iname}:${NC}\n"
      echo -e "$(ssh -p ${iport} ${iuser}@${ihost} ${cmd_to_send})"
      echo -e "\n${B_RED}================================================${NC}"
    done

    IFS="$XIFS" # Restore IFS back

  else
    echo -e "[execcmd] Usage::\nexeccmd <broadcast_set> cat /etc/hosts\nbroadcast_set values: all"
  fi
}

# ==============================================================================================#
# Helper Functions for echocmd										#
#===============================================================================================#

insertNewBashImportLine() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: insertNewBashImportLine <new .???.bash filename>" && return 1
	fi
	newFile="$1"
	if [ "${newFile: -5}" == '.bash' ]; then
		echocmd all "sed -i \"/.*\.cp.bash/a \ \ \ \ . ~\/.bash.d\/$newFile\" .bashrc"
	else
		echo "Invalid filename for import ($newFile) - must end with .bash" && return 1
	fi
}

insertNewSshAlias() {
        if [ "$#" -lt 5 ] || [ "$#" -gt 6 ] || [[ ! $1 =~ ^[0-1]$ ]]; then
                echo "Usage: insertNewSshAlias <broadcast: 1|0> <alias name> <username> <ip address> <port> [<# COMMENT for preceding line>]" && return 1
        fi

	broadcastToAllHosts="$1"
        aliasName="$2"
	sshUserName="$3"
	sshIpAddress="$4"
	sshPort="$5"
	aliasComment=""
	if [ "$#" -eq 6 ]; then
		aliasComment="$6"
	fi

	if [ "${broadcastToAllHosts}" -ne 1 ]; then
		sed -i "/.*ceres.*/a # ${aliasComment}\nalias ${aliasName}='ssh -p ${sshPort} ${sshUserName}@${sshIpAddress}'" .bash.d/.ssh.bash
	else
		echocmd all "sed -i \"/.*ceres.*/a # ${aliasComment}\nalias ${aliasName}='ssh -p ${sshPort} ${sshUserName}@${sshIpAddress}'\" .bash.d/.ssh.bash"
	fi
}

insertNewHostToIpHostsList() {
        if [ "$#" -lt 4 ] || [ "$#" -gt 5 ] || [[ ! $1 =~ ^[0-1]$ ]]; then
                echo "Usage: insertNewHostToIpHostsList <broadcast: 1|0> <short hostname> <username> <ip address> <port>" && return 1
        fi

	broadcastToAllHosts="$1"
        shortName="$2"
	sshUserName="$3"
	sshIpAddress="$4"
	sshPort="$5"

	if [ "${broadcastToAllHosts}" -ne 1 ]; then
		sed -i "/.*ceres/a ${sshUserName}@${sshIpAddress}:${sshPort}:${shortName}" .bash.d/.iphosts
	fi
}

readInHostIdArrays

fireupnewhost() {
  getIpAddressAndPort
  if [[ $ip_answer -eq 0 ]]; then
    getUsernameAndPassword
    yesNoQuestion "Proceed with ssh-copy-id (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execSshCopyId
    fi 
    yesNoQuestion "Proceed with copying all bash config to target host (existing files will be overwritten) (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execScpBashConfig
    fi
    yesNoQuestion "Proceed with copying (appending) local authorized_keys to target host (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execCopyAuthKeys
      echo "Done Keys Inbound"
    fi
    yesNoQuestion "Proceed with exporting public key of target host to all servers (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execCopyTargetKeyToLocalAuthKeys
      echo "Done Keys Outbound"
    fi
    yesNoQuestion "Proceed with inserting ssh alias for target host and .iphosts entry on all servers (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      getHostNames
      insertNewSshAlias 1 "ssh$targetNickname" "$targetUser" "$targetHost" "$targetPort" "$targetHostname"
      insertNewHostToIpHostsList 1 "$targetNickname" "$targetUser" "$targetHost" "$targetPort"
      echo "Done broadcast SSH alias creation and .iphosts insertion"
    fi
  else
    return 1
  fi
}
  
yesNoQuestion() {
  yn_question="$@"
  yn_answer=""
  while true; do
    read -n 1 -p "$yn_question " yn
    case $yn in
      [Yy]* ) echo -e ""; yn_answer=0; break;;
      [Nn]* ) echo -e ""; yn_answer=1; break;;
      * ) echo -e "\nPlease answer with yes (y) or no (n) only";;
    esac
  done
}

getIpAddressAndPort() {
  ip_success=""
  read -e -p "Enter IP address or Hostname of target host: " targetHost
  read -e -p "Enter SSH port of target device: " targetPort
  nc -z -w 4 "$targetHost" "$targetPort"
  if [ "$?" -eq 0 ]; then
    ip_success=0
  else
    yesNoQuestion "SSH service unreachable on that host:port combination. Try again? (y/n)"
    if [[ $yn_answer == 0 ]]; then
      getIpAddressAndPort
    else
      ip_success=1
    fi
  fi
}

getUsernameAndPassword() {
  read -e -p "Enter SSH username for target host: " targetUser
  read -s -p "Enter corresponding password: " targetPwd
  echo -e ""
}

getHostNames() {
  read -e -p "Enter full name of target host (hostname if known): " targetHostname
  read -e -p "Enter nickname (short, lowercase) for target host: " targetNickname
  echo -e ""
}

execSshCopyId() {
  ~/.bash.d/expect/ssh-copy-id.expect "$targetHost" "$targetPort" "$targetUser" "$targetPwd" "$USER"
  sleep 1
  echo -e ""
}

execScpBashConfig() {
  scp -r -P "$targetPort" "$HOME"/.bash.d "$targetUser@$targetHost":/home/"$targetUser"/
  sleep 1
  ssh -p "$targetPort" "$targetUser@$targetHost" "mv /home/$targetUser/.bashrc /home/$targetUser/.bashrc.bak"
  sleep 1
  scp -P "$targetPort" "$HOME"/.bashrc "$targetUser@$targetHost":/home/"$targetUser"/.bashrc
}

execCopyAuthKeys() {
  echo "1" > /dev/null 2>&1  
  scp -P "$targetPort" "$HOME"/.ssh/authorized_keys "$targetUser@$targetHost":~/.ssh/authorized_keys.tmp
  sleep 1
  echo "2" > /dev/null 2>&1
  ssh -p "$targetPort" "$targetUser@$targetHost" 'cat ~/.ssh/authorized_keys.tmp >> ~/.ssh/authorized_keys'
  sleep 1
  echo "3" > /dev/null 2>&1
  ssh -p "$targetPort" "$targetUser@$targetHost" "rm -f ~/.ssh/authorized_keys.tmp"
}

execCopyTargetKeyToLocalAuthKeys() {
  ssh -p "$targetPort" "$targetUser@$targetHost" 'cat /dev/zero | ssh-keygen -q -N ""'
  echo -e ""
  targetKey="$(ssh -p ${targetPort} ${targetUser}@${targetHost} cat /home/$targetUser/.ssh/id_rsa.pub)"
  echo "$targetKey" >> ~/.ssh/authorized_keys
  echo "Copied target host public key to local authorized_keys:"
  tail "$HOME"/.ssh/authorized_keys
  echo ""
  echocmd all "echo \"$targetKey\" " '>> ~/.ssh/authorized_keys' > /dev/null 2>&1
  echo "Copied target host public key to all server's authorized_keys:"
  echocmd all tail '~/.ssh/authorized_keys'
  echo -e "\nDone"
}

# Alt versions of functions for initialising Macs

fireupnewhostmac() {
  getIpAddressAndPort
  if [[ $ip_answer -eq 0 ]]; then
    getUsernameAndPassword
    yesNoQuestion "Proceed with ssh-copy-id (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execSshCopyId
    fi
    yesNoQuestion "Proceed with copying all bash config to target host (existing files will be overwritten) (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execScpBashConfigMac
    fi
    yesNoQuestion "Proceed with copying (appending) local authorized_keys to target host (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execCopyAuthKeysMac
      echo "Done Keys Inbound"
    fi
    yesNoQuestion "Proceed with exporting public key of target host to all servers (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      execCopyTargetKeyToLocalAuthKeysMac
      echo "Done Keys Outbound"
    fi
    yesNoQuestion "Proceed with inserting ssh alias for target host and .iphosts entry on all servers (y/n)?"
    if [[ $yn_answer == 0 ]]; then
      getHostNames
      insertNewSshAlias 1 "ssh$targetNickname" "$targetUser" "$targetHost" "$targetPort" "$targetHostname"
      insertNewHostToIpHostsList 1 "$targetNickname" "$targetUser" "$targetHost" "$targetPort"
      echo "Done broadcast SSH alias creation and .iphosts insertion"
    fi
  else
    return 1
  fi
}

execScpBashConfigMac() {
  scp -r -P "$targetPort" "$HOME"/.bash.d "$targetUser@$targetHost":/Users/"$targetUser"/
  sleep 1
  ssh -p "$targetPort" "$targetUser@$targetHost" "mv /Users/$targetUser/.bashrc /Users/$targetUser/.bashrc.bak"
  sleep 1
  scp -P "$targetPort" "$HOME"/.bashrc "$targetUser@$targetHost":/Users/"$targetUser"/.bashrc
}

execCopyAuthKeysMac() {
  echo "1" > /dev/null 2>&1
  scp -P "$targetPort" "$HOME"/.ssh/authorized_keys "$targetUser@$targetHost":~/.ssh/authorized_keys.tmp
  sleep 1
  echo "2" > /dev/null 2>&1
  ssh -p "$targetPort" "$targetUser@$targetHost" 'cat ~/.ssh/authorized_keys.tmp >> ~/.ssh/authorized_keys'
  sleep 1
  echo "3" > /dev/null 2>&1
  ssh -p "$targetPort" "$targetUser@$targetHost" "rm -f ~/.ssh/authorized_keys.tmp"
}

execCopyTargetKeyToLocalAuthKeysMac() {
  ssh -p "$targetPort" "$targetUser@$targetHost" 'cat /dev/zero | ssh-keygen -q -N ""'
  echo -e ""
  targetKey="$(ssh -p ${targetPort} ${targetUser}@${targetHost} cat /Users/$targetUser/.ssh/id_rsa.pub)"
  echo "$targetKey" >> ~/.ssh/authorized_keys
  echo "Copied target host public key to local authorized_keys:"
  tail "$HOME"/.ssh/authorized_keys
  echo ""
  echocmd all "echo \"$targetKey\" " '>> ~/.ssh/authorized_keys' > /dev/null 2>&1
  echo "Copied target host public key to all server's authorized_keys:"
  echocmd all tail '~/.ssh/authorized_keys'
  echo -e "\nDone"
}

