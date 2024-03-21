#!/bin/sh


#####################n#####################################################

# This script demonstrates the usage of API key in NetBackup REST API for listing the jobs

# This script requires jq command-line JSON parser
# if your system does not have jq installed, this will not work
# jq can be downloaded from here: https://github.com/stedolan/jq/releases

###########################################################################

port=1556
master_server=""
apikey=""

showHelp()
{
	echo ""
	echo "Invalid command parameters"
	echo "Usage:"
	echo "./apikey_usage.sh -nbmaster <master_server> -apikey <apikey>"
	echo "-nbmaster : Name of the NetBackup master server"
	echo "-apikey : API key to be used instead of JWT"
	echo ""
	exit 1
}

parseArguments()
{
	if [ $# -lt 4 ]; then
		showHelp
	fi

	while [ "$1" != "" ]; do
		case $1 in
			-nbmaster)
				master_server=$2
				;;
			-apikey)
				apikey=$2
				;;
			*)
				showHelp
				;;
		esac
		shift 2
	done

	if [ -z "$master_server" ] || [ -z "$apikey" ]; then
		showhelp
	fi
}

###############main#############

parseArguments "$@"

basepath="https://$master_server:$port/netbackup"
content_header='content-type:application/vnd.netbackup+json; version=3.0'

##############jobs##############

auth_header="authorization:$apikey"
uri="$basepath/admin/jobs"

echo "Using API key [$apikey] instead of JWT token to trigger job REST API"
curl --insecure --request GET --globoff --get "$uri"  -H "$content_header" -H "$auth_header" \
	| \
	jq '[.data[]|{JOBID: .id, TYPE: .attributes.jobType, STATE: .attributes.state, STATUS: .attributes.status}]'
exit 0
