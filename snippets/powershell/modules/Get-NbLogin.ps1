<#
.SYNOPSIS
Login to NetBackup Api.
.DESCRIPTION
Logs into the netbackup instance, via the api functions.
.EXAMPLE
Get-NbLogin
.OUTPUTS
String
Sets nbheaders var in parent script
.NOTES
FunctionName : Get-Login
Created by   : Nick Britton
#>

function Get-NbLogin()
{
$uri = $basepath + "/login"

$body = @{
    userName=$username
    password=$password
         }
$response = Invoke-WebRequest -Uri $uri -Method POST -Body (ConvertTo-Json -InputObject $body) -ContentType $nbcontent_type

if ($response.StatusCode -ne 201) { throw "Unable to connect to the Netbackup master server!" }

$content = (ConvertFrom-Json -InputObject $response)
$logintoken = $content.token
$script:nbheaders = @{  "Authorization" = $logintoken}
return $logintoken
}
