<#
.SYNOPSIS
This sample script demonstrates how to use NetBackup API to generate a new reissue token.
.DESCRIPTION
This script will generate a new reissue token for the host specified in -nbclient.
.EXAMPLE
./Get-NB-ReissueToken.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -nbclient "nb-client.example.com"
#>

param (

    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$username = $(throw "Please specify the user name using -username parameter."),
    [string]$password = $(throw "Please specify the password using -password parameter."),
    [string]$nbclient = $(throw "Please specify the client using -nbclient parameter.")

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

    # Add TLS v1.2
    try {
         if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
          [Net.ServicePointManager]::SecurityProtocol = ([Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12)

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
$content_type = "application/vnd.netbackup+json;version=2.0"

#####################################################################
# Login
#####################################################################

$uri = $basepath + "/login"

$body = @{
    userName=$username
    password=$password
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
# Get the host UUID for a hostname...
#####################################################################

$uri = $basepath + "/config/hosts"

$headers = @{
  "Authorization" = $content.token
}

$query_params = @{"name"=$nbclient} 

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the UUID for client $nbclient!"
}

$myToken = $content.token

$content = (ConvertFrom-Json -InputObject $response)

# capture the uuid...
$uuid = $content.uuid

#####################################################################
# Get Reissue token
#####################################################################

$uri = $basepath + "/security/securitytokens"

$headers = @{
  "Authorization" = $myToken
}

$body = @{
    allowedCount=1
    hostId=$uuid
    tokenName=$nbclient + "_reissue"
    type=1   
    validFor=86400 
} 
$response = Invoke-WebRequest                               `
                -Uri $uri                                   `
                -Method POST                                `
                -Body (ConvertTo-Json -InputObject $body)   `
                -ContentType $content_type                  `
                -Headers $headers

if ($response.StatusCode -ne 201)
{
    throw "Unable to connect to the Netbackup master server!"
}

$content = (ConvertFrom-Json -InputObject $response)

$content
