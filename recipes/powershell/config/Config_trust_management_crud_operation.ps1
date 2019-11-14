<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Trust Management APIs.
.DESCRIPTION
The script can be run using NetBackup 8.2 or higher.
It updates the exclude list configuration on the specified client. The exclude list is specified within the script below.
.EXAMPLE
./Config_trust_management_crud_operation.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> -TrustedMasterServerName <Trusted master Server Name> [-DomainName <domainName> -DomainType <domainType>]
#>

#Requires -Version 4.0

Param (
    [string]$MasterServer = $(Throw "Please specify the name of the NetBackup Master Server using the -MasterServer parameter."),
    [string]$UserName = $(Throw "Please specify the user name using the -UserName parameter."),
    [string]$Password = $(Throw "Please specify the password using the -Password parameter."),
    [string]$TrustedMasterServerName = $(Throw "Please specify the name of the NetBackup remote Master Server using the -TrustedMasterServerName parameter."),
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
$basepath = "https://" + $MasterServer + ":" + $port + "/netbackup"
$contentType = "application/vnd.netbackup+json;version=4.0"
$hostName = $client

######################################
# Login to the NetBackup webservices
######################################
Function Login()
{

	$uri = $basepath + "/login"

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
#####################################################################
# POST NetBackup Storage server
#####################################################################
Function CreateTrust()
{
    $base_uri = $basepath + "/config/servers/trusted-master-servers"
    
    $json = '{
      "data": {
        "type": "trustedMasterServer",
        "attributes": {
          "trustedMasterServerName": "'+$TrustedMasterServerName+'",
          "rootCAType": "NBCA",
          "authenticationType": "CREDENTIAL",
          "domainName": "DOMAIN",
          "userName": "USER",
           "password": "PASSWORD",
           "fingerprint": "FINGERPRINT"
        }
      }
    }
    '
    $response_create_trust = Invoke-WebRequest             `
                        -Uri $base_uri                `
                        -Method POST                 `
                        -Body ($json)        `
                        -ContentType $contentType  `
                        -Headers $headers
    
    if ($response_create_trust.StatusCode -ne 201)
    {
        throw "Unable to create trust between master servers." 
    }
    
    Write-Host "Trust between master servers created successfully.`n"
    echo $response_create_trust
    Write-Host $response_create_trust
    
    $response_create_trust = (ConvertFrom-Json -InputObject $response_create_trust)
}
#####################################################################
# GET NetBackup Trusted Master Server
#####################################################################
Function GetTrustedMaster() 
{

    $base_uri = $basepath + "/config/servers/trusted-master-servers/" + $TrustedMasterServerName
    
    
    $response_get = Invoke-WebRequest `
                   -Uri $base_uri `
                   -Method GET `
                   -ContentType $contentType `
                   -Headers $headers
    
    if ($response_get.StatusCode -ne 200)
    {
        throw "Unable to fetch scpecified trusted master server" 
    }
    
    Write-Host "Scpecified trusted master server fetched successfully.`n"
    Write-Host $response_get
    
    $response_get = (ConvertFrom-Json -InputObject $response_get)
}
#####################################################################
# PATCH NetBackup trust between master servers
#####################################################################
Function UpdateTrust()
{
    $base_uri = $basepath + "/config/servers/trusted-master-servers/" + $TrustedMasterServerName
    
    $json = '{
      "data": {
        "type": "trustedMasterServer",
        "attributes": {
          "trustedMasterServerName": "'+$TrustedMasterServerName+'",
          "rootCAType": "ECA"
        }
      }
    }
    '
    
    $response_update = Invoke-WebRequest             `
                        -Uri $base_uri                `
                        -Method PATCH                 `
                        -Body ($json)        `
                        -ContentType $contentType  `
                        -Headers $headers
    
    if ($response_update.StatusCode -ne 200)
    {
        throw "Unable to update trust between masters." 
    }
    
    Write-Host "Trust between masters updated successfully.`n"
    echo $response_update
    Write-Host $response_update
    
    $response_update = (ConvertFrom-Json -InputObject $response_update)

}


#####################################################################
# Delete NetBackup Trust between master Server
#####################################################################
Function DeleteTrust() 
{
    $base_uri = $basepath + "/config/servers/trusted-master-servers/" + $TrustedMasterServerName
    
    
    $response_delete = Invoke-WebRequest `
                   -Uri $base_uri `
                   -Method DELETE `
                   -ContentType $contentType `
                   -Headers $headers
    
    if ($response_delete.StatusCode -ne 204	)
    {
        throw "Unable to delete trust between masters." 
    }
    
    Write-Host "Trust between masters deleted successfully.`n"
    Write-Host $response_delete
    
    $response_delete = (ConvertFrom-Json -InputObject $response_delete)
}

###########################################################################

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
CreateTrust
GetTrustedMaster
UpdateTrust
DeleteTrust