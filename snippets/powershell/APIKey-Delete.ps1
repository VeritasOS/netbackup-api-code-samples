<#

.SYNOPSIS
This script demonstrates how to delete API key for a user (self/others). To
delete API key for other user, a user needs to have proper permissions.

.DESCRIPTION
This script will delete API Key for a user.


.EXAMPLE
./APIKey-Delete.ps1 -nbmaster <master_server_name> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_tag <apikey_tag>
-nbmaster : Name of the NetBackup master server
-login_username : User name of the user performing action
-login_password : Password of the user performing action
-login_domainname : Domain name of the user performing action
-login_domaintype : Domain type of the user performing action
-apikey_tag : Tag associate with API key to be deleted

#>

param (
    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$login_username = $(throw "Please specify the user name using -login_username parameter."),
    [string]$login_password = $(throw "Please specify the password using -login_password parameter."),   
    [string]$login_domainname = $(throw "Please specify the domain name using -login_domain_name parameter."),   
    [string]$login_domaintype = $(throw "Please specify the domain type using -login_domaintype parameter."),      
    [string]$apikey_tag = $(throw "Please specify the apikey tag using -apikey_tag parameter.")
)

#####################################################################
# Initial Setup
# Note: This allows self-signed certificates and enables TLS v1.2
#####################################################################

function InitialSetup()
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

    # Force TLS v1.2
    try {
        if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12') {
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Host $_.Exception.InnerException.Message
    }
  }
}

InitialSetup

#####################################################################
# Global Variables
#####################################################################

$port = 1556
$basepath = "https://" + $nbmaster + ":" + $port + "/netbackup"
$content_type = "application/vnd.netbackup+json;version=1.0"

#####################################################################
# Login
#####################################################################

$uri = $basepath + "/login"

$body = @{
    userName=$login_username
    password=$login_password
	 domainName=$login_domainname
	 domainType=$login_domaintype
}
$response = Invoke-WebRequest                               `
                -Uri $uri                                   `
                -Method POST                                `
                -Body (ConvertTo-Json -InputObject $body)   `
                -ContentType $content_type

if ($response.StatusCode -ne 201)
{
    throw "Unable to connect to the Netbackup master server!"
}

$content = (ConvertFrom-Json -InputObject $response)

#####################################################################
# Delete API key
#####################################################################

$uri = $basepath + "/security/api-keys/" + $apikey_tag
$content_type = "application/vnd.netbackup+json;version=3.0"

$headers = @{
  "Authorization" = $content.token
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method DELETE           	  `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 204)
{
    throw "Unable to delete API key!"
}

$response | ConvertTo-Json | ConvertFrom-Json
