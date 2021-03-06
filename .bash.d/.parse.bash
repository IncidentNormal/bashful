# ~/.bash.d/.parse.bash
#########################################################################
# >>>   .parse.bash                                                     #
#-----------------------------------------------------------------------#
# bash utility functions to aid parsing input / manipulating arrays     #
#########################################################################

function getElementIndex {

    local e
    local arr_count=0

    for e in "${@:2}"; do
        if [[ "$e" == "$1" ]]; then
            echo $arr_count
            return 0
        else
            arr_count="$(( ++arr_count ))"
        fi
    done

    echo ""
    return 1
}

function sanitizeArgument {

    #-----------------------------------------------------------#
    # NB:        ${string//substring/replacement}               #
    # Replace all matches of $substring with $replacement.      #
    #-----------------------------------------------------------#

    local retval

    if [ "$#" -ne 1 ]; then
        return 1
    fi

    suspectArgument="$1"
    cleanArgument="${suspectArgument//[^a-zA-Z0-9]/}"
    echo "$cleanArgument"

    return 0
}

function testArgumentIsNumeric {

    local retval

    if [ "$#" -ne 1 ]; then
        retval=1
    fi

    if [ "$1" -eq "$1" ] 2> /dev/null; then
        retval=0
    else
        retval=2
    fi

    return $retval
}

function testArgumentIsIPv4Address {

    if [ "$#" -ne 1 ]; then
        return 1
    fi

    local ip=$1
    local retval=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then

        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS

        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        retval=$?

    fi

    return $retval
}
