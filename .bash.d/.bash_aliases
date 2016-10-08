# ~/.bash.d/.bash_aliases: see below
#########################################################################
# >>>   .bash_aliases                                                   #
#-----------------------------------------------------------------------#
# aliases and 1-line functions to make common tasks faster 		#
#########################################################################

# quickly source the .bashrc file
alias srcbash='. ~/.bashrc'

# ls aliases
alias ls='ls --color'
alias ll='ls -alh --color'
alias la='ls -lA --color'
alias l='ls'

# safe file management
alias cp='cp -iv'
alias rm='rm -i'
alias mv='mv -i'

# quick directory movement
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# go to the last directory you were in
alias back='cd $OLDPWD'

# display numbers in a human readable format
alias df='df -h'
alias du='du -h'
alias free='free -h'

# copy the current working directory to the clipboard
alias cpwd='pwd | xclip -selection clipboard'

# quickly find files and directory
alias ff='find . -type f -name'
alias fd='find . -type d -name'

## ack-grep
alias ack='ack-grep'

# echo to stderr (hur hur, errcho)
alias errcho='>&2 echo'

# tmux default alias is tmux='tmux -u' -u switch detects the UTF charset and changes the ACS line chars accordingly
alias tmux='tmux'

# get internet speed
alias speedtest='wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test500.zip'

# get external ip
alias extip='curl -s icanhazip.com'

# git number aliases (https://github.com/holygeek/git-number)
alias st='git status'
alias gn='git number'
alias ga='git number add'

# change the current directory to the parent directory that contains the .git folder
alias git-root='cd "`git rev-parse --show-toplevel`"'

# print the path with each directory separated by a newline
alias path='echo -e ${PATH//:/\\n}'

# list the name of the process matched with pgrep
alias pgrep='pgrep -l'

# make less properly handle colored output
alias lessr='less -R'

# open any file in GNOME from the command line
alias gopen='gvfs-open'

# start programs quietly
alias gdb='gdb -q'
alias bc='bc -ql'

# adb logcat aliases
alias logcat-sys='adb logcat -s System.out:D'
alias logcat-e='adb logcat -s *:E'

# key management aliases: fingerprint a pubkey and retrieve pubkey from a private key
alias fingerprint='ssh-keygen -lf'
alias pubkey='ssh-keygen -y -f'

# display hexdump in canonical form
alias hd='hexdump -C'

# print the current time
alias now='date +%T'

# Wake on LAN (Magic Packet) (-> PC: Titan)
alias wolpc='sudo etherwake -D e8:00:12:34:56:ff'
alias wolvenus'wakeonlan -i 192.168.20.255 -p 9 e8:00:12:34:56:ff'

# Timer using the 'watch' command:
alias timer='export ts=$(date +%s);p='\''$(date -u -d @"$(($(date +%s)-$ts))" +"%H.%M.%S")'\'';watch -n 1 -t banner $p;eval "echo $p"'

# timer10 is a countDOWN from 10 seconds (hardcoded), after zero it goes to 23:59:59 tho lol 
alias timer10='export ts=$(($(date +%s) + 10));p='\''$(date -u -d @"$(($ts - $(date +%s)))" +"%H.%M.%S")'\'';watch -n 1 -t banner $p;eval "echo $p"'

# countdown is like timer10, but the time to count from is passed in as the parameter 
function countdown { inargs="$@"; export cts=$(($(date +%s) + $inargs)); tdiff='$(date -u -d @"$(($cts - $(date +%s)))" +"%H.%M.%S")'; watch -n 1 -t banner $tdiff; eval "echo $tdiff"; }

# Restart network using NetworkManager cli tool
function restartnetwork { nmcli -p networking off && nmcli -p networking on; }

# List number of connections per IP address on 5 second loop
function ipcx { sudo clear;while x=0; do clear;date;echo "";echo "  [Count] | [IP ADDR]";echo "-------------------";sudo netstat -np|grep :80|grep -v LISTEN|awk '{print $5}'|cut -d: -f1|uniq -c; sleep 5;done; }

# Netcat test host ($1) on port ($2)
function ncp { nc -z -w 4 "$1" "$2"; echo $([ "$?" -eq 0 ] && echo "Success" || echo "Fail with code: \"$?\""); }

#list all local IP addresses:
function iplist { ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}'; }

#################################################################################################
# lnx :: symbolic link $(ln -s) helper!								#
#################################################################################################
function lnx {
  echo -e "====================== Symlink Helper ======================\n     real command is \"ln -s <target> <portal>\" btw \n============================================================\n[1] enter full path of TARGET directory/file:"
  read -e -i "$(pwd)" targetPath
  echo
  echo -e "[2] enter full path of the magic portal to the faraway land (the symlink):"
  read -e -i "$(pwd)" symPath
  echo
  targetPath=$(echo $targetPath | tr -d [:cntrl:])
  if [ ! -d $symPath ] && [ ! -f $symPath ]; then
    realTargetPath=$(realpath $targetPath)
    realSymPath=$(realpath $symPath)
    ln -s $realTargetPath $realSymPath > /dev/null 2>&1;
    if [ -d "$realSymPath" ] || [ -f "$realSymPath" ]; then
      echo -e "Created, have a look:\n\n"
      cd "$(dirname $realSymPath)"
      ls -l
    else
      echo -e "Failed, probably entered an invalid path, check: $targetPath ($realTargetPath) and $symPath ($realSymPath)"
    fi
  else
    echo -e "You can't make the symlink where there already is a real thing! Think about it...\n Try again?"
    echo -n "(y/N): "
    read retryChoice
    echo
    if [[ "$retryChoice" == "Y" || "$retryChoice" == "y" ]]; then
      lnx
    else
      echo "Done."
    fi
  fi
}
