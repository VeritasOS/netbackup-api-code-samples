<#
.SYNOPSIS
Get client or host details from master server
.DESCRIPTION
Gets the host details for each client on the master and will return the details in an array.
See https://Masterserver:1556/api-docs/index.html?urls.primaryName=config#/Hosts/get_config_hosts for details on the api used.
.EXAMPLE
Get-NbClientInfo
.OUTPUTS
Array
.NOTES
FunctionName : Get-NbClientInfo
Created by   : Nick Britton
#>

function Get-NbClientInfo()
{
$uri = $basepath + "/config/hosts"
$response = Invoke-WebRequest -Uri $uri -Method GET -ContentType $nbcontent_type -Headers $nbheaders
if ($response.StatusCode -ne 200){ throw "Unable to get the client details"}
$content = (ConvertFrom-Json -InputObject $response)
$nbClientInfo = $content.hosts
Return $nbClientInfo
}
