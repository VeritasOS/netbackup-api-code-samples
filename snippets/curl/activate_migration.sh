#!/bin/sh

#####################n#####################################################

# This script demonstrates how to activate the new CA.
# To activate the CA migration, a user needs to have proper permissions.

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
force=0
reason=""

showHelp()
{
	echo ""
	echo "Invalid command parameters"
	echo "Usage:"
	echo "./activate_migration.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domain_name> -login_domaintype <login_domaintype> [-reason | -r <reason_for_migration>] [-force | -f]"
	echo "-nbmaster         : Name of the NetBackup master server"
	echo "-login_username   : User name of the user performing action"
	echo "-login_password   : Password of the user performing action"
	echo "-login_domainname : Domain name of the user performing action"
	echo "-login_domaintype : Domain type of the user performing action"
	echo "-reason | -r      : Reason for activation of the new CA"
	echo "-force | -f       : Forcefully activate the new CA"
	echo ""
	exit 1
}

parseArguments()
{
	if [ $# -lt 10 ] && [ $# -gt 14 ]; then
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
			-force|-f)
				force=1
				;;
			-reason|-r)
				reason=$2
				;;
			*)
				showHelp
				;;
		esac
		shift 2
	done

	if [ -z "$master_server" ] || [ -z "$login_username" ] || [ -z "$login_password" ] || [ -z "$login_domainname" ] || [ -z "$login_domaintype" ]; then
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
content_header='content-type:application/vnd.netbackup+json;version=4.0'
uri="$basepath/security/certificate-authorities/activate"

# Construct request body
request_body="{"
request_body="${request_body}\"data\": {"
request_body="${request_body}\"type\": \"nbcaMigrationActivateRequest\","
request_body="${request_body}\"attributes\": {"
if [ $force == 1 ]; then
    request_body="${request_body}\"force\" : \"true\""
fi
request_body="${request_body}}}}"

if [ -z $reason ]; then
    curl --silent -k -X POST "$uri" -H "$content_header" -H "$auth_header" -d "$request_body" | jq
else
    audit_reason="X-NetBackup-Audit-Reason:$reason";
    curl --silent -k -X POST "$uri" -H "$content_header" -H "$auth_header" -H "$audit_reason" -d "$request_body" | jq
fi

exit 0
