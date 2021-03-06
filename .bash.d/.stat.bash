# ~/.bash.d/.stat.bash
#########################################################################
# >>>   .stat.bash							#
#-----------------------------------------------------------------------#
# aliases & functions for parsing filesystem related output... 		#
# + some general helper functions.					#
#########################################################################

# 
# nmf
# PAINSTAKINGLY PERFECTED
# Finds $1 most recently modified files in current dir
# Returns newline separated "ls -l" stats of each file
function nmf { find . -type f -printf '%T@ ' -print0 -printf '\n' | sort -rn | head -"$1" |  cut -f2- -d" " | tr -d "\0" | tr "\n" "\0" | xargs -0 ls -Ulh; }

# locnmf
# Based on $(nmf) above. Takes $(locate) results and tabulates them into columns with last access/modified/changed datetimes
function locnmf { locate -0 "$1" | xargs -0 stat --printf="%.X %n\n" | sort -rn | cut -f2- -d" " | tr -d "\0" | xargs -n 1 stat --printf="%.19x\t %n\t %s\n" | column -t; }

# lsn
# returns output like 'ls -l' except with numeric permissions (think chmod) like 0755 rather than drwxr-xr-x
alias lsn='ls -la | awk "{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\"%0o \",k);print}"'

# lsx
# as above except passes through and handles additional NON-HYPHENATED arguments for native 'ls'
# see lsz for full explanation (lsz is equivalent, except for taking hyphenated arguments)
function lsx { ls -l$1 | awk "{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\"%0o \",k);print}"; }

# lsz
# As above except passes through, and handles, additional arguments (for native 'ls' command)
# these additional arguments are IN ADDITION to '-l' which is implicit. Examples:
# '-h' would pass through 'ls -l -h' and hence return human readable filesizes
# '-h -R' would pass through 'ls -l -h -R' and hence recursively search subdirectories in addition to returning human readables sizes for all found files
function lsz {
    ls -l "$@" | awk "{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\"%0o \",k);print}";
}

# lst
# Returns 'ls -l' grepped for files modified today only
# No left-filling of zeros in digit dates:
alias lst="ls -l | grep '$(date +%b\ %_d)'"
# With left-filled zeros in digit dates:
alias lstdd="ls -l | grep $(date +%b\\\ %d)"

# listvars
# List all environment variables
alias listvars=' ( set -o posix; set ) | less'

# tabulated sysadmin helpers:
# contents of passwd
alias userinfo='column -tns: /etc/passwd'
# contents of netstat:
alias ntstprocs="sudo netstat -pnut -W | column -t -s $'\t'"

# catx
# returns all filenames of all files matching the mask given as paramater (e.g. .smb*) WITH CONTENTS underneath
function catx { tail -n +1 -- "$@"; }

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

# check alignment of disk partitions:
function fdpchk { sudo fdisk -l /dev/sda | grep -E sda[0-9]+ | sed s/*// | awk '{printf ("%s %f ",$1,$2/512); if($2%512){ print "BAD" }else {print "Good"} }' | column -t; }

# extract
# Extract any compressed archive:
function extract {
   if [ -f $1 ] ; then
       case $1 in
        *.tar.bz2)      tar xvjf $1 && cd $(basename "$1" .tar.bz2) ;;
        *.tar.gz)       tar xvzf $1 && cd $(basename "$1" .tar.gz) ;;
        *.tar.xz)       tar Jxvf $1 && cd $(basename "$1" .tar.xz) ;;
        *.xz)           unxz $1 && cd $(basename "$1" .xz) ;;
        *.bz2)          bunzip2 $1 && cd $(basename "$1" /bz2) ;;
        *.rar)          unrar x $1 && cd $(basename "$1" .rar) ;;
        *.gz)           gunzip $1 && cd $(basename "$1" .gz) ;;
        *.tar)          tar xvf $1 && cd $(basename "$1" .tar) ;;
        *.tbz2)         tar xvjf $1 && cd $(basename "$1" .tbz2) ;;
        *.tgz)          tar xvzf $1 && cd $(basename "$1" .tgz) ;;
        *.zip)          unzip $1 && cd $(basename "$1" .zip) ;;
        *.Z)            uncompress $1 && cd $(basename "$1" .Z) ;;
        *.7z)           7z x $1 && cd $(basename "$1" .7z) ;;
        *)              echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
 }

# datediff
# Author: Nathan Coulter
MPHR=60    # Minutes per hour.
HPD=24     # Hours per day.

function datediff {
        if [ $# -eq 2 ]; then
                CURRENT=$(date -u -d "$1" '+%F %T.%N %Z')
                TARGET=$(date -u -d "$2" '+%F %T.%N %Z')
        fi
        if [ -n "${CURRENT+x}" ] && [ -n "${TARGET+x}" ]; then
                printf '%s' $(( $(date -u -d"$TARGET" +%s) - $(date -u -d"$CURRENT" +%s)))
#                       %d = day of month.
        else
                echo -e "Usage: datediff <current date> <target date>\nThese must be in ISO format e.g. '2007-09-01 17:30:24'"
        fi
}

# lnx 
# Symbolic link $(ln -s) helper! 
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


