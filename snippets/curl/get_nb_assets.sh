!/bin/sh

#####################n#####################################################

# This script demonstrates the usage of netbackup REST API for listing
# the assets

# This script requires jq command-line JSON parser
# if your system does not have jq installed, this will not work
# jq can be downloaded from here: https://github.com/stedolan/jq/releases

###########################################################################

port=1556
master_server=""
username=""
password=""
domainname=""
domaintype=""

showHelp()
{
        echo ""
        echo "Invalid command parameters"
        echo "Usage:"
        echo "./get_nb_vmservers.sh -nbmaster <master_server> -username <username> -password <password> -domainname <dname> -domaintype <unixpwd/nt>"
        echo ""
        exit 1
}

parseArguments()
{
        if [ $# -lt 6 ]; then
                showHelp
        fi

        while [ "$1" != "" ]; do
                case $1 in
                        -nbmaster)
                                master_server=$2
                                ;;
                        -username)
                                username=$2
                                ;;
                        -password)
                                password=$2
                                ;;
                        -domainname)
                                domainname=$2
                                ;;
                        -domaintype)
                                domaintype=$2
                                ;;
                        *)
                                showHelp
                                ;;
                esac
                shift 2
        done

        if [ -z "$master_server" ] || [ -z "$username" ] || [ -z "$password" ] || [ -z "$domainname" ] || [ -z "$domaintype" ]; then
                showhelp
        fi

        if [ "${domaintype^^}" = "WINDOWS" ] || [ "${domaintype^^}" = "NT" ]; then
                domaintype="nt"
        fi
}

uriencode()
{
        jq -nr --arg v "$1" '$v|@uri';
}
###############main############

parseArguments "$@"

master_server=$master_server.$domainname
basepath="https://$master_server:$port/netbackup"
content_header='content-type:application/json'

##############login#############

uri="$basepath/login"
echo $uri

data=$(jq --arg name $username --arg pass $password --arg dname $domainname --arg dtype $domaintype \
                --null-input '{userName: $name, password: $pass}')

jwt=$(curl -k -X POST $uri -H $content_header -d "$data" | jq --raw-output '.token')

### To use filter page[limit] in URI, The key 'page[limit]' must be url encoded already. ###
### Curl --data-urlencode encodes only the content part of the data of the form 'name=content' ###
param1="$(uriencode 'page[limit]')=10" #op: page%5Blimit%5D=10
param2="$(uriencode 'page[offset]')=0"


##############jobs##############
auth_header="authorization:$jwt"
uri="$basepath/asset-service/workloads/vmware/assets"

curl --insecure --request  GET --globoff --get $uri  -H $content_header -H $auth_header \
        --data-urlencode "$param1" \
        --data-urlencode "$param2" \
        | \
        jq '[.data[]|{Type: .type, ID: .id, 
                AssetType: .attributes.assetType, 
                DisplayName: .attributes.commonAssetAttributes.displayName,
                HostName: .attributes.commonAssetAttributes.masters[].hostName,
                UUID: .attributes.commonAssetAttributes.masters[].uuid,
                DataCenter: .attributes.datacenter,
                vCenter: .attributes.vCenter,
                vCenterVersion: .attributes.vCenterVersion
        }]'

exit 0
