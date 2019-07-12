<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Services REST APIs.
.DESCRIPTION
This script can be run using NetBackup 8.2 and higher.
We can get all the NB services or individual service along with their status.
.EXAMPLE
./get_services.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> -Client <client> [-DomainName <domainName> -DomainType <domainType>]
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
$servicesUri = "admin/hosts/";
$contentType = "application/vnd.netbackup+json;version=3.0"
$hostName = $Client
$testServiceName = "bpcd"

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
	
#######################
# List all nb services
#######################

Function ListNbServices()
{
	$uri = $baseUri + $servicesUri + $uuid + "/services"

	Write-Host "`nSending a GET request to list all nb services on client $client...`n"
	$response = Invoke-WebRequest `
				-Uri $uri `
				-Method GET `
				-ContentType $contentType `
				-Headers $headers

	if ($response.StatusCode -ne 200)
	{
		throw "Unable to list Nb Services on client $client.`n"
	}

	$content = (ConvertFrom-Json -InputObject $response)

	$content | ForEach-Object {
		
		$properties = 
	   
		@{Label = "Service Name"; Expression = { $_.id }},
		@{Label = "Status"; Expression = { $_.attributes.status }}

	   $content.data | Format-Table -AutoSize -Property $properties

   }

}

#########################
# List a Specific Service
#########################

Function ListNBService()
{
	$uri = $baseUri + $servicesUri + $uuid + "/services/" + $testServiceName

	Write-Host "`nSending a GET request to list specific Service on client $client ..`n"
	$response = Invoke-WebRequest `
			-Uri $uri `
			-Method GET `
			-ContentType $contentType `
			-Headers $headers

	if ($response.StatusCode -ne 200)
	{
	throw "Unable to read service $testServiceName on client $client.`n"
	}
	$content = (ConvertFrom-Json -InputObject $response)

	$properties = 

	@{Label = "Service Name"; Expression = { $_.id }},
	@{Label = "Status"; Expression = { $_.attributes.status }}

	$content.data | Format-Table -AutoSize -Property $properties
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
$uuidResponse = getUUID
$uuid = $uuidResponse.hosts[0].uuid
ListNBService
ListNbServices
