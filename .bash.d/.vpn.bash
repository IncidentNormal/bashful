# ~/.bash.d/.vpn.bash
###############################################################
#!/bin/bash

BASH_HOME=$HOME/.bash.d
source $BASH_HOME/.geo.bash
source $BASH_HOME/.parse.bash

IPLOG_PATH="$HOME/.iplog"
VPN_CONF_PATH="/etc/openvpn"
VPN_MAIN_CONF_FILE="vpnx.conf"
VPN_MAIN_CONF_FILE_PATH="${VPN_CONF_PATH}/${VPN_MAIN_CONF_FILE}"
DEBUG_LOG_FILE_PATH="$HOME/.iplogcrondebug.log"
GEOLOC_LOG_FILE_PATH="$HOME/.gloc.log"
LAST_NATURAL_IP_FILE="$HOME/.last_known_natural_ip"
if [ -f "$LAST_NATURAL_IP_FILE" ]; then SXIP=$(cat $LAST_NATURAL_IP_FILE) && export SXIP; fi

TRDAEMON="transmission-daemon"
TRDAEMONBIN=/usr/bin/${TRDAEMON}
TRUSER=debian-transmission

VPNLIST=( france germany sweden switzerland luxembourg finland nl1 nl2 nl3 italy lithuania poland portugal romania spain coventry london portsmouth )

if [ -z $CURRENT_VPN_INDEX ]; then
    if [ -f "$VPN_MAIN_CONF_FILE_PATH" ]; then

        current_vpn_target_path=$(readlink "$VPN_MAIN_CONF_FILE_PATH")
        current_vpn_file=$(basename "$current_vpn_target_path")
        current_vpn_name="${current_vpn_file%.ovpn}"
        arr_count=0

        for vpn_entry in "${VPNLIST[@]}"; do

            if [ "${vpn_entry}" == "${current_vpn_name}" ]; then
                CURRENT_VPN_INDEX=$arr_count ; export CURRENT_VPN_INDEX
                CURRENT_VPN_NAME="${VPNLIST[$CURRENT_VPN_INDEX]}" ; export CURRENT_VPN_NAME
            else
                arr_count="$(( ++arr_count ))"
            fi

        done

    else
        CURRENT_VPN_INDEX=0 ; export CURRENT_VPN_INDEX
        CURRENT_VPN_NAME="" ; export CURRENT_VPN_NAME
    fi
fi


function getExtIp {
    echo "$(curl -s icanhazip.com)"
}

function storeNaturalExtIpInFile {

    naturalExtIp="$(getNaturalExtIp)"
    if [ "$?" -eq 0 ]; then
        echo "$naturalExtIp" > $LAST_NATURAL_IP_FILE
        return 0
    else
        return 1
    fi
}

function getNaturalExtIp {

    naturalExtIp="$(ssh -p 55567 ares@192.168.20.43 curl -s icanhazip.com)"

    if $(testArgumentIsIPv4Address "$naturalExtIp"); then
        echo "$naturalExtIp"
        return 0
    else
        return 1
    fi
}

function iplogcron {

    local ipnow="$(getExtIp)"

    storeNaturalExtIpInFile
    SXIP="$(cat $LAST_NATURAL_IP_FILE)"
    if [ -n "$SXIP" ]; then
        export SXIP
    fi

    echo -e "$(date) ::\t ${ipnow} ::\t Natural IP:[${SXIP}]" >> "${IPLOG_PATH}"

    if [ $(chkvpnargs ${ipnow}) -ne 0 ]; then

        vpnDownMsg=$(echo "VPN DOWN:\t IP=${ipnow} \t VPN_INDEX=${CURRENT_VPN_INDEX} \t VPN_NAME=${VPNLIST[$CURRENT_VPN_INDEX]}")
        echo -e "$vpnDownMsg" >> "$DEBUG_LOG_FILE_PATH"
        echo -e "$vpnDownMsg"

        forceSwitchVpnConnection

    else

        vpnOkMsg=$(echo "VPN OK:\t IP=${ipnow} \t VPN_INDEX=${CURRENT_VPN_INDEX} \t VPN_NAME=${VPNLIST[$CURRENT_VPN_INDEX]}")
        echo -e "$vpnOkMsg"

    fi
}

function parseForceSwitchArgs {

    local changeIndex

    if [ "$#" -eq 1 ]; then

        if [ $(testArgumentIsNumeric "$1") ]; then
            changeIndex=$1
        else
            inputArg="$1"
            CLEANSTRING="$(sanitizeArgument ${inputArg})"
            element_index=$(getElementIndex "$CLEANSTRING" "${VPNLIST[@]}")

            if [ "$?" -eq 0 ]; then
                changeIndex="$element_index"
            else
                echo " > > > INPUT [$CLEANSTRING] INVALID CHOICE :: Choose value from [${VPNLIST[@]}] < < <"
                return 1
            fi
        fi

        if [ -n "$changeIndex" ]; then

            if [ "$changeIndex" -eq 0 ]; then
                CURRENT_VPN_INDEX="$(( ${#VPNLIST[@]} - 1 ))" ; export CURRENT_VPN_INDEX ; echo " > > > CHANGING VPN TO [${VPNLIST[$changeIndex]}] :: index [$changeIndex] > > >"
            elif [ "$changeIndex" -lt "${#VPNLIST[@]}" ]; then
                CURRENT_VPN_INDEX="$(( $changeIndex - 1 ))" ; export CURRENT_VPN_INDEX ; echo " > > > CHANGING VPN TO [${VPNLIST[$changeIndex]}] :: index [$changeIndex] > > >"
            else
                echo " > > > INDEX [$changeIndex] OUT OF RANGE :: CHOOSE VALUE FROM 0 TO $(( ${#VPNLIST[@]} - 1 )) < < <"
                return 1
            fi

        fi
    fi

    return 0

}

function forceSwitchVpnConnection {

    local numArgs="$#"
    local calledByUser
    local calledStateCode="$(ps -o stat= -p $$)" &>/dev/null

    if [[ "$calledStateCode" =~ .*\+ ]] && [ "$numArgs" -eq 0 ]; then
        calledByUser="true"
        local nextVpnIndex

        [[ $CURRENT_VPN_INDEX -ne $(( ${#VPNLIST[@]} - 1 )) ]] && nextVpnIndex=$(( $CURRENT_VPN_INDEX + 1 )) || nextVpnIndex=0

        echo " > > > CHANGING VPN TO [${VPNLIST[$nextVpnIndex]}] :: index [$nextVpnIndex] > > >"
    fi

    if [ -n "$numArgs" ] && [ "$numArgs" -gt 0 ]; then

        parseForceSwitchArgs $@
        if [ $? -ne 0 ]; then
            return 1
        fi

        calledByUser="true"
    fi

    echo -e "\n\n:\t:\t:\t:\t FORCE SWITCH VPN CONNECTION\t :\t:\t:\t:\n" >> "$DEBUG_LOG_FILE_PATH"
    echo "$(date) :: *** Enter vpnRotateConfig" >> "$DEBUG_LOG_FILE_PATH"

    vpnRotateConfig

    echo "$(date) :: *** Enter vpnReload" >> "$DEBUG_LOG_FILE_PATH"

    if [ "$(vpnReload)" = 0 ]; then
        echo "$(date) :: > > > SUCCESS *** vpnReload returned 0, so we can start $TRDAEMON again" >> "$DEBUG_LOG_FILE_PATH"

        sudo service "$TRDAEMON" start >> "$DEBUG_LOG_FILE_PATH" 2>&1

        local extIp="$(getExtIp)"
        geoLocMsg=$(echo "New VPN Location: $(getGeoLocFromIp $extIp) :: [IP Address: $extIp]")
        echo "$geoLocMsg" >> "$DEBUG_LOG_FILE_PATH"

        if [ "$calledByUser" = "true" ]; then
            echo "$geoLocMsg"
        fi
    fi
}

function stopTransmissionDaemon {

    local retval=2
    local counter=0

    while [ $retval -gt 1 ]; do

        echo "$(date) :: *** Enter isServiceRunning: $TRDAEMON ... count = $counter" >> "$DEBUG_LOG_FILE_PATH"
        result="$(isServiceRunning $TRDAEMON)"

        if [ "$result" = 0 ]; then
            echo "$(date) :: > > > isServiceRunning returned 0 (not running) - so now we return 0" >> "$DEBUG_LOG_FILE_PATH"
            retval=0
        elif [ $counter -gt 4 ]; then
            echo "$(date) :: > > > isServiceRunning returned 1 (running) 5 times in a row - so now we return 1" >> "$DEBUG_LOG_FILE_PATH"
            retval=1
        else
            echo "$(date) :: > > > isServiceRunning returned 1 (running) - so we try to stop $TRDAEMON and then sleep for 1 second (count = $counter)" >> "$DEBUG_LOG_FILE_PATH"

            sudo service "$TRDAEMON" stop >> "$DEBUG_LOG_FILE_PATH" 2>&1
            sleep 1

            counter="$(( ++counter ))"
        fi

    done

    echo $retval
}

function vpnReload {

    echo "$(date) :: *** Enter stopTransmissionDaemon" >> "$DEBUG_LOG_FILE_PATH"

    stopTDResult="$(stopTransmissionDaemon)"

    echo "$(date) :: --- Leaving stopTransmissionDaemon. retval = $stopTDResult" >> "$DEBUG_LOG_FILE_PATH"

    if [ "$stopTDResult" = 0 ]; then
        echo "$(date) :: > > > stopTransmissionDaemon returned 0 (successfully stoppped) so now we restart openvpn service..." >> "$DEBUG_LOG_FILE_PATH"

        local retval=2
        local counter=0

        while [ $retval -gt 1 ]; do
            echo "$(date) :: > > > Restart openvpn and then wait 10 seconds before checking IP Address (attempt no. $counter)" >> "$DEBUG_LOG_FILE_PATH"

            sudo service openvpn restart >> "$DEBUG_LOG_FILE_PATH" 2>&1
            sleep 16

            echo "$(date) :: *** Enter checkvpn [check for non domestic IP Address...]" >> "$DEBUG_LOG_FILE_PATH"

            if [ "$(chkvpn)" = 0 ]; then
                echo "$(date) :: > > > SUCCESS *** IP Address is: [$(getExtIp)] *** return 0" >> "$DEBUG_LOG_FILE_PATH"
                retval=0
            elif [ $counter -gt 4 ]; then
                echo "$(date) :: ~ ~ ~ FAILURE --- IP Address inaccessible/unchanging [$SXIP] after 5 attempts --- return 1" >> "$DEBUG_LOG_FILE_PATH"
                retval=1
            else
                sleep 4
                counter="$(( ++counter ))"
            fi

        done

        echo $retval
    fi
}

# Check ext IP isnt $SXIP
# Human readable
function checkvpn {

    if [ -f "$LAST_NATURAL_IP_FILE" ]; then SXIP=$(cat $LAST_NATURAL_IP_FILE) && export SXIP; fi
    local xip="$(getExtIp)"

    if [ -z "$xip" ]; then
        echo "$(date) :: *** VPN Momentary Failure - External IP Cannot be Acquired"
    elif [[ "$xip" == "$SXIP" ]]; then
        echo "$(date) :: *** VPN Failure - External IP = [$xip]"
    else
        echo "$(date) :: *** VPN Success - External IP = [$xip]"
    fi
}

# Returns 0 (success) or 1 (fail)
function chkvpn {

    if [ -f "$LAST_NATURAL_IP_FILE" ]; then SXIP=$(cat $LAST_NATURAL_IP_FILE) && export SXIP; fi
    local xip="$(getExtIp)"

    if  [ -n "$xip" ] && [[ "$xip" != "$SXIP" ]]; then
        echo 0
    else
        echo 1
    fi
}

# As above but takes IP argument to compare with
function chkvpnargs {

    if [ -n "$1" ]; then

        if [ -f "$LAST_NATURAL_IP_FILE" ]; then SXIP=$(cat $LAST_NATURAL_IP_FILE) && export SXIP; fi
        local xip="$1"

        if [[ "$xip" != "$SXIP" ]]; then
            echo 0
        else
            echo 1
        fi

    else
        echo 1
    fi
}

function vpnRotateConfig {

    if [ -n $CURRENT_VPN_INDEX ]; then

        echo "$(date) :: > > > CURRENT_VPN_INDEX: $CURRENT_VPN_INDEX" >> "$DEBUG_LOG_FILE_PATH"

        (( ++CURRENT_VPN_INDEX )); export CURRENT_VPN_INDEX

        if [ $CURRENT_VPN_INDEX -eq ${#VPNLIST[@]} ]; then
            CURRENT_VPN_INDEX=0; export CURRENT_VPN_INDEX
        fi

        echo "$(date) :: > > > NEW_VPN_INDEX: $CURRENT_VPN_INDEX" >> "$DEBUG_LOG_FILE_PATH"

        nextVpn="${VPNLIST[$CURRENT_VPN_INDEX]}"
        echo "$(date) :: > > > nextVpn: $nextVpn" >> "$DEBUG_LOG_FILE_PATH"

        nextVpnConfPath="${VPN_CONF_PATH}/${nextVpn}.ovpn"
        echo "$(date) :: > > > nextVpnConfPath: $nextVpnConfPath" >> "$DEBUG_LOG_FILE_PATH"

        rm -f "${VPN_MAIN_CONF_FILE_PATH}"
        ln -s "${nextVpnConfPath}" "${VPN_MAIN_CONF_FILE_PATH}"

        CURRENT_VPN_NAME=${nextVpn}; export CURRENT_VPN_NAME

    fi
}

function isServiceRunning {

    if [ -n $1 ]; then

        local service="$1"
        echo "$(date) :: > > > isServiceRunning? service: $service" >> "$DEBUG_LOG_FILE_PATH"

        if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 )); then
            echo "$(date) :: > > > YES *** $service IS running." >> "$DEBUG_LOG_FILE_PATH"
            echo 1
        else
            echo "$(date) :: ~ ~ ~ NO --- $service is NOT running." >> "$DEBUG_LOG_FILE_PATH"
            echo 0
        fi

    else
        >&2 echo "$(date) :: *** Usage: $0 <name_of_service>"
    fi
}

###############################################################################################
#       ALIASES                                                                               #
###############################################################################################

alias extip='curl -s icanhazip.com'
alias gextip='curl freegeoip.net/json/$(extip)'
alias fsvpn='forceSwitchVpnConnection'
