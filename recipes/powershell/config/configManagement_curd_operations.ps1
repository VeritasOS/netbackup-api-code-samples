<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Hosts Configuration APIs.
.DESCRIPTION
The script can be run using NetBackup 8.2 or higher.
It updates the exclude list configuration on the specified client. The exclude list is specified within the script below.
.EXAMPLE
./configManagement_curd_operations.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> -Client <client> [-DomainName <domainName> -DomainType <domainType>]
#>

#Requires -Version 4.0

Param (
    [string]$MasterServer = $(Throw "Please specify the name of the NetBackup Master Server using the -MasterServer parameter."),
    [string]$UserName = $(Throw "Please specify the user name using the -UserName parameter."),
    [string]$Password = $(Throw "Please specify the password using the -Password parameter."),
	[string]$Client = $(Throw "Please specify the client name using the -client parameter."),
    [string]$DomainName,
    [string]$DomainType
)


###############################################################
# Setup to allow self-signed certificates and enable TLS v1.2
###############################################################
Function Setup()
{
    # Allow self-signed certificates
    if ([System.Net.ServicePointManager]::CertificatePolicy -notlike 'TrustAllCertsPolicy')
    {
        Add-Type -TypeDefinition @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy
    }

    # Force TLS v1.2
    try {
        if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Host "`n"$_.Exception.InnerException.Message
    }
}

####################
# Global Variables
####################

$port = 1556
$baseUri = "https://" + $MasterServer + ":" + $port + "/netbackup/"
$HostsUri = "config/hosts/"
$contentType = "application/vnd.netbackup+json;version=3.0"
$hostName = $client
$Configurations = "/configurations/exclude"

######################################
# Login to the NetBackup webservices
######################################
Function Login()
{

	$uri = $baseUri + "login"

	$body = @{
		userName=$UserName
		password=$Password
	}
	if ($DomainName -ne "") {
		$body.add("domainName", $DomainName)
	}
	if ($DomainType -ne "") {
		$body.add("domainType", $DomainType)
	}
	Write-Host "`nSending a POST request to login to the NetBackup webservices...`n"

	$response = Invoke-WebRequest `
				-Uri $uri `
				-Method POST `
				-Body (ConvertTo-Json -InputObject $body) `
				-ContentType $contentType

	if ($response.StatusCode -ne 201)
	{
		throw "Unable to connect to the NetBackup Master Server"
	}

	Write-Host "Login successful.`n"
	$content = (ConvertFrom-Json -InputObject $response)
    return $content
}
#########################
# Get a Host uuid
#########################
Function getUUID()
{
	$uri = $baseUri + "config/hosts?filter=" + $hostName


	Write-Host "`nSending a GET request to get host UUID ..`n"
	
	$response = Invoke-WebRequest `
				-Uri $uri `
				-Method GET `
				-ContentType $contentType `
				-Headers $headers

	if ($response.StatusCode -ne 200)
	{
		throw "Unable to get host UUID.`n"
	}

	Write-Host "fetched UUID successfully.`n"
	$content = (ConvertFrom-Json -InputObject $response)
	return $content
}
	
#############################
#Get a Exclude config Setting
##############################

Function getConfigSetting()
{
	$uri = $baseUri + $HostsUri + $uuid + $configurations

	Write-Host "`nSending a GET request to get a Exclude List...`n"
	
	$response = Invoke-WebRequest `
				-Uri $uri `
				-Method GET `
				-ContentType $contentType `
				-Headers $headers

	if ($response.StatusCode -ne 200)
	{
		throw "Unable get the Exclude List.`n"
	}

	$content = (ConvertFrom-Json -InputObject $response)
	
    Write-Host "`nExclude List for the given host...`n"
	
    foreach ($value in $content.data.attributes.value) {$value}

}

#########################
# Update the Exclude List
#########################

Function updateConfigSetting()
{
	$uri = $baseUri + $HostsUri + $uuid + $configurations 
    
	$value = @("C:\\Program Files\\Veritas\\NetBackup\\bin\\*.lock",
        "C:\\Program Files\\Veritas\\NetBackup\\bin\\bprd.d\\*.lock",
        "C:\\Program Files\\Veritas\\NetBackup\\bin\\bpsched.d\\*.lock",
        "C:\\Program Files\\Veritas\\Volmgr\\misc\\*",
        "C:\\Program Files\\Veritas\\NetBackupDB\\data\\*",
		"C:\\test0",
		"C:\\test1"
	)
	
    $data = @{
        type="hostConfiguration"
        id="exclude"
        attributes=@{value=$value}
}
	
	$body = @{data=$data} | ConvertTo-Json -Depth 9
	
	Write-Host "`nSending a Update request to update a Exclude List...`n"
	
	$response = Invoke-WebRequest `
				-Uri $uri `
				-Method PUT `
				-Body $body `
				-ContentType $contentType `
				-Headers $headers

	if ($response.StatusCode -ne 204)
	{
		throw "Unable to update the Exclude List.`n"
	}

	
	Write-Host "`nSuccessfully  Updated the Exclude List...`n"

}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
$uuidResponse = getUUID
$uuid = $uuidResponse.hosts[0].uuid
getConfigSetting
updateConfigSetting
Write-Host "`nNow get the updated Exclude List...`n"
getConfigSetting
