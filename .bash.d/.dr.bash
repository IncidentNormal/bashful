# ~/.bash.d/.dr.bash
#########################################################################
# >>>   .dr.bash	                                                #
#-----------------------------------------------------------------------#
# bash framework for controlling Android phone via adb		        #
#########################################################################

########################
# CONNECTION CONSTANTS #
########################

adbport='5555'
adbip='192.168.20.222'
adbmac='45:23:01:ef:cd:ab'

alias nxwifi="adb tcpip $adbport && adb connect $adbip"

alias ash="adb -s $adbip:$adbport shell"

PHONE_NAME='android-34439839abcfde3a'; export PHONE_NAME
PHONE_MAC='45:23:01:ef:cd:ab'; export PHONE_MAC
PHONE_IP='192.168.20.222'; export PHONE_IP

# SCREEN CONSTANTS

PIX_CENTRE_L_R=700 #500
PIX_CENTRE_U_D=1100 #800

removeSkewVals() {
  PIX_CENTRE_L_R=700 #500
  PIX_CENTRE_U_D=1100 #800
}

########################
# CONNECTION FUNCTIONS #
########################

nxConnect() {
  if [ -x $PHONE_IP ]; then
    findAndroidIPAddr
    echo "[nxConnect] >> Retrying with new IP Address [$PHONE_IP]" 2>&1
    nxConnect
  else
    echo "[nxConnect] >> Connecting to IP Address [$PHONE_IP]" 2>&1
    adbdev=$(adb devices)
    echo "$adbdev"
    if [[ $adbdev == *"5555"* ]]
      then
      if [[ $adbdev != *"off"* ]]
        then
        echo "[nxConnect] >> Device connected successfully :)" 2>&1
        echo 0
      else
        echo "[nxConnect] >> Device present but offline, reconnecting" 2>&1
        adbReconnect
      fi
    else
      #abd devices found no device
      echo "[nxConnect] >> No device registered, attempt to create connection to [$PHONE_IP]" 2>&1
      adb connect "$PHONE_IP"
      nxConnect
    fi
  fi
}

findAndroidIPAddr() {
  arpList=`arp -a`
  foundAndroidPhone=`echo -e "$arpList" | grep "$PHONE_NAME\|$PHONE_MAC"`
  if [ -n "$foundAndroidPhone" ]; then
    PHONE_IP=`echo $foundAndroidPhone | cut -d "(" -f2 | cut -d ")" -f1`
    echo "[findAndroidIPAddr] >> Found [$PHONE_NAME]:: Has IP address [$PHONE_IP]" 2>&1
    export PHONE_IP
  else
    echo "[findAndroidIPAddr] >> Phone not found on network" 2>&1
    return 1
fi
}

adbReconnect() {
  adb disconnect
  echo "[adbReconnnect] >> adb disconnect" 2>&1
  sleep 0.4
  adb kill-server
  echo "[adbReconnnect] >> kill-server" 2>&1  
  sleep 0.4
  echo "[adbReconnnect] >> connect to $PHONE_IP" 2>&1 
  adb connect $PHONE_IP
  sleep 0.2
  echo "[adbReconnnect] >> nxConnect" 2>&1
  nxConnect
}

#########################
# BASIC INPUT FUNCTIONS #
#########################

# UTILITY FUNCTIONS

# Convert Input to Escaped Text
validateAndEscapeText() {
  inText="$@"
  escText="${inText//\ /\%s}"
  escText="${escText//\"/\'\"\'}"
  escText="${escText//\(/\\\(}" 
  escText="${escText//\)/\\\)}"
  echo "$escText"
}

# Validate Input for PIN Code functions
validateNumPadInput() {
  re='^[0-9]+$'
  if [[ $@ =~ $re  ]]; then
    echo 0
  elif [[ $@ == OK ]]; then
    echo 0
  else
    echo 1
  fi
}

# Enter PIN Digit
enterNumPadDigit() {
  if [[ $@ == 0 ]]; then
    adb shell input tap 500 1470
  elif [[ $@ == 1 ]]; then
    adb shell input tap 200 800
  elif [[ "$@" == 2 ]]; then
    adb shell input tap 500 800
  elif [[ "$@" == 3 ]]; then
    adb shell input tap 850 800
  elif [[ "$@" == 4 ]]; then
    adb shell input tap 200 1000
  elif [[ "$@" == 5 ]]; then
    adb shell input tap 500 1000
  elif [[ "$@" == 6 ]]; then
    adb shell input tap 850 1000
  elif [[ "$@" == 7 ]]; then
    adb shell input tap 200 1200
  elif [[ "$@" == 8 ]]; then
    adb shell input tap 500 1200
  elif [[ "$@" == 9 ]]; then
    adb shell input tap 850 1200
  elif [[ "$@" == OK ]]; then
    adb shell input tap 850 1470
  else
    echo "Invalid PIN value [$@] try again using 0-9 or OK: one at a time"
  fi
  sleep 0.1
}

# Enter HC PIN Digit
enterHCnumPadDigit() {
  if [[ "$@" == 0 ]]; then
    adb shell input tap 500 1800
  elif [[ "$@" == 1 ]]; then
    adb shell input tap 200 800
  elif [[ "$@" == 2 ]]; then
    adb shell input tap 500 800
  elif [[ "$@" == 3 ]]; then
    adb shell input tap 850 800
  elif [[ "$@" == 4 ]]; then
    adb shell input tap 200 1100
  elif [[ "$@" == 5 ]]; then
    adb shell input tap 500 1100
  elif [[ "$@" == 6 ]]; then
    adb shell input tap 850 1100
  elif [[ "$@" == 7 ]]; then
    adb shell input tap 200 1400
  elif [[ "$@" == 8 ]]; then
    adb shell input tap 500 1400
  elif [[ "$@" == 9 ]]; then
    adb shell input tap 850 1400
  elif [[ "$@" == OK ]]; then
    adb shell input tap 200 1800
  else
    echo "Invalid PIN value [$@] try again using 0-9 or OK: one at a time"
  fi
}


#################
# TAP FUNCTIONS #
#################

nxtap() {
  inVars=$@
  if [ "$#" -eq 2 ]; then
    inX=$1
    inY=$2
    isXn=$(validateNumPadInput "$inX")
    isYn=$(validateNumPadInput "$inY")
    if [[ $isXn == 0 && $isYn == 0 ]]; then
      retVal=$(nxConnect)
      if [[ "${retVal: -1}" == 0 ]]; then
        adb shell input tap $inX $inY
      else
        echo "Unable to connect to phone [$retVal]"
      fi
    else
      echo "Invalid Co-ordinates [$inX $inY]"
    fi
  else
    echo "Invalid number of arguments, must be 2 (x y)"
  fi
}

#################
# KEY FUNCTIONS #
#################

sendKeys() {
  inVars="$@"
  keyVal=""
  repVal=0
  if [ "$#" -eq 2 ]; then
    keyVal="$1"
    repVal="$2"
  elif [ "$#" -eq 1 ]; then
    keyVal="$1"
    repVal=1
  else
    echo "[sendKeys] Invalid number of arguments, must be 1 (key) or 2  (key, number of presses)" 2>&1 
    return 1
  fi
  for (( i=0; i<$repVal; i++ )); do
    sendKeyPress $keyVal
  done
}

sendKeyPress() {
  keyVal="$@"
  if [[ "$keyVal" == enter || "$keyVal" == return || "$keyVal" == cr || "$keyVal" == e ]]; then
    adb shell input keyevent 66
  elif [[ "$keyVal" == del || "$keyVal" == b ]]; then
    adb shell input keyevent 67
  elif [[ "$keyVal" == longdel || "$keyVal" == ldel ]]; then
    sendLongDelete 3500    
  elif [[ "$keyVal" == down || "$keyVal" == dn || "$keyVal" == d ]]; then
    adb shell input keyevent 20
  elif [[ "$keyVal" == up || "$keyVal" == u ]]; then
    adb shell input keyevent 19
  elif [[ "$keyVal" == left || "$keyVal" == l ]]; then
    adb shell input keyevent 21
  elif [[ "$keyVal" == right || "$keyVal" == r ]]; then
    adb shell input keyevent 22
  elif [[ "$keyVal" == clear ]]; then
    adb shell input keyevent 28
  elif [[ "$keyVal" == hcsend ]]; then
    adb shell input tap 1060 1550
  else
    echo "[sendKeyPress] key press [$keyVal] not supported, use one of: [cr del u d l r clear hcsend]" 2>&1 
  fi
}

# Enter PIN Code
enterNumPadCode() {
  inCode=$@
  isCodeValid=$(validateNumPadInput "$inCode")
  if [[ $isCodeValid == 0 ]]; then
    for (( i=0; i<${#inCode}; i++ )); do
      enterNumPadDigit ${inCode:$i:1}
    done
    enterNumPadDigit OK
  fi
}


# Send Escaped Text
sendText() {
  inText="$@"
  escText=$(validateAndEscapeText $inText)
  adb shell input text $escText
}

# Send Back Button Press
nxb() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    nxtap 200 2500;
  else
    echo "[nxb] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

#########################
# OPERATIONAL FUNCTIONS #
#########################

# Send Home Button Press
nxh() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    nxtap 700 2500;
  else
    echo "[nxh] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Menu Button Press (Bottom Right, invokes Window Selection Mode)
nxm() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    nxtap 1200 2500;
  else
    echo "[nxm] Unable to connect to phone [$retVal]" 2>&1 
  fi
}


# Swipe down Notifications Panel from Top Screen
nxn() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    swipeTopDown;
  else
    echo "[nxn] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Power Button Press
nxp() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    powerBtn;
  else
    echo "[nxp] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Login PIN
nxpin() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    echo -n "Enter PIN:"
    read -s stdinPin
    echo
    powerBtn
    swipe up
    #enterNumPadCode $stdinPin
    nxt "$stdinPin"
  else
    echo "[nxpin] Failed to connect to phone [$retVal]" 2>&1 
  fi
}

# Send HC PIN
hcpin() {
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    echo -n "Enter PIN:"
    read -s stdinPin
    echo 
    isCodeValid=$(validateNumPadInput "$stdinPin")
    if [[ $isCodeValid == 0 ]]; then
      for (( i=0; i<${#stdinPin}; i++ )); do
        enterHCnumPadDigit ${stdinPin:$i:1}
      done
      enterHCnumPadDigit OK
    fi
  else
    echo "[hcpin] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Text
nxt() {
  inText="$@"
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    sendText $inText
  else
    echo "[nxt] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Key
nxk() {
  inVars="$@"
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    sendKeys $inVars
    #sendKeyPress $inText
  else
    echo "[nxk] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Search in Google Bar
nxs() {
  inText="$@"
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
     searchVal="$@"
     nxh
     adb shell input tap 200 150
     nxt $inText
  else
    echo "[nxs] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

# Send Intent (default: no args = display co-ord grid)
nxi() {
  incVar="$@"
  retVal=$(nxConnect)
  if [[ "${retVal: -1}" == 0 ]]; then
    if [ $# -gt 0 ]; then
      inIntent=("$incVar")
      if [[ "${inIntent[0]}" == "-p" ]]; then
        echo "[nxi] Phone auto-unlocking process added to event queue..." 2>&1 
        nxpin
        intentVal="${inIntent[@]:1}"
        if [ -z "$intentVal" ]; then
          adb shell am broadcast -a uk.incidentnormal.intent.launchoverlay 2>&1 > /dev/null
        fi        
      fi
    else
      intentVal="${inIntent[@]:1}"
      if [ -z "$intentVal" ]; then
        adb shell am broadcast -a uk.incidentnormal.intent.launchoverlay 2>&1 > /dev/null
      fi
    fi
  else
    echo "[nxi] Unable to connect to phone [$retVal]" 2>&1 
  fi
}

###################
# SWIPE FUNCTIONS #
###################

# Send Swipe with input arguments (direction):
# adb base ccommand usage: [touchscreen|touchpad|touchnavigation] swipe <x1> <y1> <x2> <y2> [duration(ms)]
swipe() {
  inVars=$@
  numVars=$#
  $(removeSkewVals)
  swipeSkew=0
  swipeDir="none"
  
  if [[ "$numVars" -eq 2 ]]; then 
    swipeSkew="$2"
  fi
  if [[ "$numVars" -eq 1 || "$numVars" -eq 2 ]]; then 
    swipeDir="$1"
    retVal=$(nxConnect)
    if [[ "${retVal: -1}" == 0 ]]; then
      if [[ "$swipeDir" == up ]]; then
        PIX_CENTRE_L_R="$((PIX_CENTRE_L_R+$swipeSkew))"
        swipeUp
      elif [[ "$swipeDir" == down ]]; then
        PIX_CENTRE_L_R="$((PIX_CENTRE_L_R-$swipeSkew))"
        swipeDown
      elif [[ "$swipeDir" == left ]]; then
	PIX_CENTRE_U_D="$((PIX_CENTRE_U_D+$swipeSkew))"        
	swipeLeft
      elif [[ "$swipeDir" == right ]]; then
	PIX_CENTRE_U_D="$((PIX_CENTRE_U_D-$swipeSkew))"        
	swipeRight
      elif [[ "$swipeDir" == topdown ]]; then
        swipeTopDown
      else
        echo "[swipe] Invalid swipe direction [$@] try again using one of [up down left right topdown]" 2>&1 
      fi
    else
      echo "[swipe] Unable to connect to phone [$retVal]" 2>&1 
    fi
  else
    echo "[swipe] Invalid number of parameters ($numVars). Swipe supports either:" 2>&1 
    echo "[swipe] 1:	direction [up,right,left,down]" 2>&1 
    echo "[swipe] 2:	direction, and distance from centre [- or + number of pixels, referred to as skew]" 2>&1 
  fi
}

# Swipe aliases
swipeLeft() { adb shell input swipe "$PIX_CENTRE_U_D" "$PIX_CENTRE_L_R" 10 "$PIX_CENTRE_L_R" 50; }
swipeRight() { adb shell input swipe 10 "$PIX_CENTRE_L_R" "$PIX_CENTRE_U_D" "$PIX_CENTRE_L_R" 50; }
swipeUp() { adb shell input swipe "$PIX_CENTRE_L_R" "$((PIX_CENTRE_U_D+200))" "$PIX_CENTRE_L_R" 100 500; }
swipeDown() { adb shell input swipe "$PIX_CENTRE_L_R" 100 "$PIX_CENTRE_L_R" "$((PIX_CENTRE_U_D+200))" 500; }
swipeTopDown() { adb shell input swipe "$PIX_CENTRE_L_R" 4 "$PIX_CENTRE_L_R" "$((PIX_CENTRE_U_D+200))" 500; }
powerBtn () { adb shell input keyevent 26; }


#########################
# Quick n dirty aliases # 
#########################

# Reliant on core functions

# 8 Circles at Bottom:
# 1)
nx1() {
  nxh
  nxtap 100 2400
}

nx2() {
  nxh
  nxtap 260 2400
}

nx3() {
  nxh
  nxtap 470 2400
}

nx4() {
  nxh
  nxtap 640 2400
}

nx5() {
  nxh
  nxtap 820 2400
}

nx6() {
  nxh
  nxtap 1000 2400
}

nx7() {
  nxh
  nxtap 1170 2400
}

nx8() {
  nxh
  nxtap 1340 2400
}

# Google Authenticator
nxauth() {
  nxn
  nxtap 100 600
  sleep 0.5
  swipe up
}

# Screen Keep Awake Toggle
nxscr() {
  nxn
  nxtap 500 600
  nxb
}

# Bluetooth Toggle
nxbt() {
  nxn
  nxtap 1000 400
  nxb
} 

# WhatsApp Send Message
nxwasend() {
  nxtap 1400 2400
  nxb
}

# HC Send Message
nxhcsend() {
  nxtap 1410 2200
  nxb
}
