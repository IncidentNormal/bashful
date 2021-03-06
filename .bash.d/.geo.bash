# ~/.bash.d/.geo.bash
#########################################################################
# >>>   .geo.bash                                                     	#
#-----------------------------------------------------------------------#
# bash utility functions for geocoding & reverse geocoding		#
#########################################################################

# IP UTILITY FUNCTIONS 
function validip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function getWanIp() {
  echo "$(curl -s icanhazip.com)"
}

###############################################################################################
#     GEOCODING FUNCTIONS                                                                     #
###############################################################################################

function getGeoLocFromIp()
{
    local print_lat_lon

    if [ "$#" -eq 1 ] && [ "$1" != "-h" ] && $(validip $1); then
        print_lat_lon=false
    elif [ "$#" -eq 2 ] && [ "$2" = "-l" ] && $(validip $1); then
        print_lat_lon=true
    else
        echo -e "getGeoLocFromIp (alias: glocip)\nReturns: reverse geocoded city and country of IP address\nUsage: getGeoLocFromIp <valid ipv4 address> [-h] [-l]\n -h: Print this usage stub\n -l: Additionally output latitude and longitude" >&2
        return 1
    fi

    local ip="$1"

    local lat_lon=$(getLatLonFromIp ${ip})
    local stat=$?
    if [ $stat -ne 0 ]; then return $stat; fi

    local city_country=$(getCityCountryFromLatLon "${lat_lon}")
    local stat=$?
    if [ $stat -ne 0 ]; then return $stat; fi

    if [ "$print_lat_lon" = true ]; then
        echo "${city_country} [${lat_lon}]"
    else
        echo "${city_country}"
    fi

    return 0
}

function getLatLonFromIp()
{
    if [ "$#" -ne 1 ] || [ $(validip $1) ]; then
        echo -e "Usage: getLatLonFromIp <valid ipv4 address>" >&2
        return 1
    fi

    local ip="$1"
    local lat_lon=$(curl -s -m 1 "freegeoip.net/json/${ip}")

    if [ -z "${lat_lon}" ] || [[ "${lat_lon}" =~ Backend\ not\ available ]] || [[ ! "${lat_lon}" =~ .*latitude.* ]]; then
        echo -e "Failure to access geocoding API; either:\n - Network connectivity is compromised\n - API calls to freegeoip.net are being blocked\n - freegeoip.net have changed their API\nInvestigate." >&2
        return 1
    else
        lat_lon="$(echo ${lat_lon} | jq -r '.latitude, .longitude')"
        lat_lon="$(echo ${lat_lon} | tr ' ' ',')"
    fi

    echo "${lat_lon}"

    return 0
}

function getCityCountryFromLatLon()
{
    local latlon=""

    if [ "$#" -eq 1 ] && [ -n "$1" ]; then
        latlon="$1"
    elif [ "$#" -eq 2 ] && [ -n "$1" ] && [ -n "$2" ]; then
        local lat="$1"
        local lon="$2"
        latlon="${lat},${lon}"
    else
        echo -e "Usage: getCityCountryFromLatLon {<latitude> <longitude>|<latitude,longitude>}" >&2
        return 1
    fi

    mapfile -t city_country < <(curl -G -k --data "latlng=$latlon&sensor=false" http://maps.googleapis.com/maps/api/geocode/xml 2>/dev/null | xmlstarlet sel -t -v '/GeocodeResponse/result[1]/address_component[type="political"][type="country"]/long_name' -n -t -v '/GeocodeResponse/result[1]/address_component[type="political"][type="locality"]/long_name')

    if [ "${#city_country[@]}" -lt 2 ]; then
        echo -e "Failed to parse geocoding API, either:\n - Network connectivity is compromised\n - API calls to maps.googleapis.com are being blocked\n - maps.googleapis.com has changed its API\nInvestigate." >&2
        return 1
    fi

    local country="${city_country[0]}"
    local city="${city_country[1]}"

    echo "${city}, ${country}"

    return 0
}

###############################################################################################
#       ALIASES                                                                               #
###############################################################################################

alias gloc='getGeoLocFromIp $(getExtIp)'
alias glocip='getGeoLocFromIp'
alias latlonip='getLatLonFromIp'
