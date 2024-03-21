#!/bin/sh

#####################n#####################################################

# This script demonstrates how to delete API key of a user (self/others). To
# delete API key for other user, a user needs to have proper permissions.

# This script requires jq command-line JSON parser
# if your system does not have jq installed, this will not work.
# jq can be downloaded from here: https://github.com/stedolan/jq/releases

###########################################################################

port=1556
master_server=""
login_username=""
login_password=""
login_domainname=""
login_domaintype=""
apikey_tag=""

showHelp()
{
	echo ""
	echo "Invalid command parameters"
	echo "Usage:"
	echo "./apikey_delete.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_tag <apikey_tag>"
	echo "-nbmaster : Name of the NetBackup master server"
	echo "-login_username : User name of the user performing action"
	echo "-login_password : Password of the user performing action"
	echo "-login_domainname : Domain name of the user performing action"
	echo "-login_domaintype : Domain type of the user performing action"
	echo "-apikey_tag : Tag associate with API key to be deleted"
	echo ""
	exit 1
}

parseArguments()
{
	if [ $# -ne 12 ]; then
		showHelp
	fi

	while [ "$1" != "" ]; do
		case $1 in
			-nbmaster)
				master_server=$2
				;;
			-login_username)
				login_username=$2
				;;
			-login_password)
				login_password=$2
				;;
			-login_domainname)
				login_domainname=$2
				;;
			-login_domaintype)
				login_domaintype=$2
				;;
			-apikey_tag)
				apikey_tag=$2
				;;
			*)
				showHelp
				;;
		esac
		shift 2
	done

	if [ -z "$master_server" ] || [ -z "$login_username" ] || [ -z "$login_password" ] || [ -z "$login_domainname" ] || [ -z "$login_domaintype" ] || [ -z "$apikey_tag" ]; then
	   showHelp
	fi

	if [ "${login_domaintype^^}" = "WINDOWS" ] || [ "${login_domaintype^^}" = "NT" ]; then
		login_domaintype="nt"
	fi
}

###############main############

parseArguments "$@"

basepath="https://$master_server:$port/netbackup"
content_header='content-type:application/json'

##############login#############

uri="$basepath/login"

data=$(jq --arg name $login_username --arg pass $login_password --arg dname $login_domainname --arg dtype $login_domaintype \
		--null-input '{userName: $name, password: $pass, domainName: $dname, domainType: $dtype}')

jwt=$(curl --silent -k -X POST $uri -H $content_header -d "$data" | jq --raw-output '.token')

##############jobs##############

auth_header="authorization:$jwt"
content_header='content-type:application/vnd.netbackup+json; version=3.0'
uri="$basepath/security/api-keys/$apikey_tag"

curl --silent -k -X DELETE "$uri" -H "$content_header" -H "$auth_header" | jq

exit 0
