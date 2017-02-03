# ~/.bash.d/.dns.bash
#########################################################################
# >>>   .dns.bash                                                       #
#-----------------------------------------------------------------------#
# bash framework for interacting with the Namecheap DNS API		#
#########################################################################

#!/bin/bash

SANDBOX=true

PRODUCTION_API_USER=foo
PRODUCTION_API_KEY=4332131fabbabbcbdbbdabb222222
PRODUCTION_USERNAME=sandy_foo

SANDBOX_API_USER=sandy_foo
SANDBOX_API_KEY=0293741abcdef0123456789ffffff
SANDBOX_USERNAME=sandy_foo

PRODUCTION_SERVICE_URL='https://api.namecheap.com/xml.response'
SANDBOX_SERVICE_URL='https://api.sandbox.namecheap.com/xml.response'

API_USER=
API_KEY=
USERNAME=
SERVICE_URL=

if [ "${SANDBOX}" == "false" ]; then
	API_USER="${PRODUCTION_API_USER}"
	API_KEY="${PRODUCTION_API_KEY}"
	USERNAME="${PRODUCTION_USERNAME}"
	SERVICE_URL="${PRODUCTION_SERVICE_URL}"
else
	API_USER="${SANDBOX_API_USER}"
	API_KEY="${SANDBOX_API_KEY}"
	USERNAME="${SANDBOX_USERNAME}"
	SERVICE_URL="${SANDBOX_SERVICE_URL}"
fi

CLIENT_IP="$(getExtIp)"

function getDomainList()
{
	COMMAND='namecheap.domains.getList'

        request="${SERVICE_URL}?ApiUser=${API_USER}&ApiKey=${API_KEY}&UserName=${USERNAME}&ClientIp=${CLIENT_IP}&Command=${COMMAND}"
	curl "$@" "${request}"
}

function getDomainInfo()
{
	COMMAND='namecheap.domains.getinfo'
	ARGS=""
	if [ "$#" -gt 1 ]; then
		ARGS="${@:2}"
	fi
	DOMAIN_NAME="$1"

        request="${SERVICE_URL}?ApiUser=${API_USER}&ApiKey=${API_KEY}&UserName=${USERNAME}&ClientIp=${CLIENT_IP}&Command=${COMMAND}&DomainName=${DOMAIN_NAME}"
	curl ${ARGS} "${request}"

	echo -e "\n\t -\t -\t -\t -\t -\n"

	getDomainHosts "${DOMAIN_NAME}" ${ARGS}
}

function getDomainHosts()
{
        COMMAND='namecheap.domains.dns.getHosts'
        ARGS=""
        if [ "$#" -gt 1 ]; then
                ARGS="${@:2}"
        fi
        DOMAIN_NAME="$1"

	parseDomainNameToSldAndTld "${DOMAIN_NAME}" SLD TLD

        request="${SERVICE_URL}?ApiUser=${API_USER}&ApiKey=${API_KEY}&UserName=${USERNAME}&ClientIp=${CLIENT_IP}&Command=${COMMAND}&SLD=${SLD}&TLD=${TLD}"
        curl ${ARGS} "${request}"
}

function checkDomains()
{
	COMMAND='namecheap.domains.check'
	DOMAIN_LIST='nebularz-ok.co.uk,nebularz-ok.com,nebularz-ok.uk'

        request="${SERVICE_URL}?ApiUser=${API_USER}&ApiKey=${API_KEY}&UserName=${USERNAME}&ClientIp=${CLIENT_IP}&Command=${COMMAND}&DomainList=${DOMAIN_LIST}"
	curl "$@" "${request}"
}

function changeDomainIpAddress()
{
	ARGS=""
        if [ "$#" -gt 1 ]; then
                ARGS="${@:3}"
        fi
        DOMAIN_NAME="$1"
	NEW_IP="$2"

	parseDomainNameToSldAndTld "${DOMAIN_NAME}" SLD TLD

	declare -a HOST_NAMES=('@' 'www')
	RECORD_TYPE='A'
	TTL='1800' #default

	COMMAND='namecheap.domains.dns.setHosts'
	
	request="${SERVICE_URL}?ApiUser=${API_USER}&ApiKey=${API_KEY}&UserName=${USERNAME}&Command=${COMMAND}&ClientIp=${CLIENT_IP}&SLD=${SLD}&TLD=${TLD}&HostName1=${HOST_NAMES[0]}&RecordType1=${RECORD_TYPE}&Address1=${NEW_IP}&HostName2=${HOST_NAMES[1]}&RecordType2=${RECORD_TYPE}&Address2=${NEW_IP}"

	curl ${ARGS} "${request}"
}

# Assign variable one scope above the caller.
# Usage: local "$1" && upvar $1 value [value ...]
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
function upvar() {
    if unset -v "$1"; then           # Unset & validate varname
        if (( $# == 2 )); then
            eval $1=\"\$2\"          # Return single value
        else
            eval $1=\(\"\${@:2}\"\)  # Return array
         fi
    fi
}

function parseDomainNameToSldAndTld()
{
	if [ "$#" -ne 3 ]; then
                echo -e "Usage: parseDomainNameToSldAndTld <domainName> <sld_var> <tld_var>\nReturns: <domainName> split into <sld_var> & <tld_var>\n" && exit 1
        fi

	domainName="$1"

	IFS='.' read -r __sld __tld <<< "$domainName"

	local "$2" && upvar $2 "$__sld"
	local "$3" && upvar $3 "$__tld"
}
