<#

.SYNOPSIS
This script demonstrates how to create API key for a user (self/others). To
create API key for other user, a user needs to have proper permissions.

.DESCRIPTION
This script will create API Key for a user.


.EXAMPLE
./APIKey-Create.ps1 -nbmaster <master_server_name> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> [-apikey_username <apikey_username> [-apikey_domainname <apikey_domain_name>] -apikey_domaintype <apikey_domaintype>] -expiryindays <expiryindays> -description <description>
-nbmaster : Name of the NetBackup master server
-login_username : User name of the user performing action
-login_password : Password of the user performing action
-login_domainname : Domain name of the user performing action
-login_domaintype : Domain type of the user performing action
-apikey_username : (Optional) User name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self
-apikey_domainname : Domain name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self. Blank in case -apikey_domaintype parameter is 'unixpwd'
-apikey_domaintype : Domain type of the user for whom API key needs to be generated. Optional in case API key is to be generated for self
-expiryindays : Number of days from today after which API key should expire
-description : A textual description to be associated with API key

#>

param (
    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$login_username = $(throw "Please specify the user name using -login_username parameter."),
    [string]$login_password = $(throw "Please specify the password using -login_password parameter."),   
    [string]$login_domainname = $(throw "Please specify the domain name using -login_domain_name parameter."),   
    [string]$login_domaintype = $(throw "Please specify the domain type using -login_domaintype parameter."),      
    [string]$expiryindays = $(throw "Please specify the expiry period in days using -expiryindays parameter."),   
    [string]$description = $(throw "Please specify the description using -description parameter."),
    [string]$apikey_username,   
    [string]$apikey_domainname,   
    [string]$apikey_domaintype
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
# Create API key
#####################################################################

$uri = $basepath + "/security/api-keys"
$content_type = "application/vnd.netbackup+json;version=3.0"

$headers = @{
  "Authorization" = $content.token
}

# Construct request body
if ($apikey_username -ne "" -and $apikey_domaintype -ne "")
{
	$request_body = @{
		data = @{
			type = 'apiKeyCreationRequest'
			attributes = @{
				description = $description
				expireAfterDays = "P" + $expiryindays + "D"
			    userName = $apikey_username
				userDomain = $apikey_domainname
				userDomainType = $apikey_domaintype
			}
		}
	}

}
else {
	$request_body = @{
		data = @{
			type = 'apiKeyCreationRequest'
			attributes = @{
				description = $description
				expireAfterDays = "P" + $expiryindays + "D"
			}
		}
	}
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method POST                   `
                -Body (ConvertTo-Json -InputObject $request_body)           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 201)
{
    throw "Unable to create API key!"
}

$response | ConvertTo-Json | ConvertFrom-Json
