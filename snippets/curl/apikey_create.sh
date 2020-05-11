#!/bin/sh

#####################n#####################################################

# This script demonstrates how to create API key for a user (self/others). To
# create API key for other user, a user needs to have proper permissions.

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
apikey_username=""
apikey_domainname=""
apikey_domaintype=""
expiryindays=""
description=""
apikey_other_user=0

showHelp()
{
	echo ""
	echo "Invalid command parameters"
	echo "Usage:"
	echo "./apikey_create.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domain_name> -login_domaintype <login_domaintype> [-apikey_username <apikey_username> [-apikey_domainname <apikey_domain_name>] -apikey_domaintype <apikey_domaintype>] -expiryindays <expiry_in_days> -description <description>"
	echo "-nbmaster : Name of the NetBackup master server"
	echo "-login_username : User name of the user performing action"
	echo "-login_password : Password of the user performing action"
	echo "-login_domainname : Domain name of the user performing action"
	echo "-login_domaintype : Domain type of the user performing action"
	echo "-apikey_username : (Optional) User name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self"
	echo "-apikey_domainname : Domain name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self. Do not specify this parameter if -apikey_domaintype parameter is 'unixpwd'"
	echo "-apikey_domaintype : Domain type of the user for whom API key needs to be generated. Optional in case API key is to be generated for self"
	echo "-expiryindays : Number of days from today after which API key should expire"
	echo "-description : A textual description to be associated with API key"
	echo ""
	exit 1
}

parseArguments()
{
	if [ $# -ne 14 ] && [ $# -ne 18 ] && [ $# -ne 20 ]; then
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
			-apikey_username)
				apikey_username=$2
				apikey_other_user=1
				;;
			-apikey_domainname)
				apikey_domainname=$2
				apikey_other_user=1
				;;
			-apikey_domaintype)
				apikey_domaintype=$2
				apikey_other_user=1
				;;
			-expiryindays)
				expiryindays=$2
				;;
			-description)
				description=$2
				;;
			*)
				showHelp
				;;
		esac
		shift 2
	done

	if [ -z "$master_server" ] || [ -z "$login_username" ] || [ -z "$login_password" ] || [ -z "$login_domainname" ] || [ -z "$login_domaintype" ] || [ -z "$expiryindays" ] || [ -z "$description" ]; then
	   showHelp
	fi
	
	if [ $apikey_other_user -eq 1 ]; then
		if [ -z "$apikey_username" ] || [ -z "$apikey_domaintype" ]; then
			showHelp
		fi
	fi

	if [ "${login_domaintype^^}" = "WINDOWS" ] || [ "${login_domaintype^^}" = "NT" ]; then
		login_domaintype="nt"
	fi

	if [ "${apikey_domaintype^^}" = "WINDOWS" ] || [ "${apikey_domaintype^^}" = "NT" ]; then
		apikey_domaintype="nt"
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
uri="$basepath/security/api-keys"

# Construct request body
request_body="{"
request_body="${request_body}\"data\": {"
request_body="${request_body}\"type\": \"apiKeyCreationRequest\","
request_body="${request_body}\"attributes\": {"
request_body="${request_body}\"description\" : \"${description}\","
request_body="${request_body}\"expireAfterDays\": \"P${expiryindays}D\""
if [ $apikey_other_user == 1 ]; then
	request_body="${request_body},\"userName\": \"${apikey_username}\","
	request_body="${request_body}\"userDomain\": \"${apikey_domainname}\","
	request_body="${request_body}\"userDomainType\": \"${apikey_domaintype}\""
fi
request_body="${request_body}}}}"

curl --silent -k -X POST "$uri" -H "$content_header" -H "$auth_header" -d "$request_body" | jq

exit 0
