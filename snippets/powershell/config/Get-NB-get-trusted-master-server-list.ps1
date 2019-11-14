<#

.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for fetching trusted master server list.

.DESCRIPTION
This script will fetch trusted master server list.

.EXAMPLE
./Get-NB-get-trusted-master-server-list.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret"
#>

param (
    [string]$nbmaster    = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),
    [string]$username    = $(throw "Please specify the user name using -username parameter."),
    [string]$password    = $(throw "Please specify the password using -password parameter.")
)

#####################################################################
# Initial Setup
# Note: This allows self-signed certificates and enables TLS v1.2
#####################################################################

function InitialSetup()
{

  [Net.ServicePointManager]::SecurityProtocol = "Tls12"

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
    [Net.ServicePointManager]::SecurityProtocol = "Tls12"
    
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
$content_type1 = "application/vnd.netbackup+json;version=1.0"
$content_type2 = "application/vnd.netbackup+json;version=2.0"


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
                -ContentType $content_type1

if ($response.StatusCode -ne 201)
{
    throw "Unable to connect to the Netbackup master server!"
}
Write-Host "Login successful.`n"
$content = (ConvertFrom-Json -InputObject $response)

#####################################################################
# GET NetBackup Trusted master Server List
#####################################################################

$headers = @{
  "Authorization" = $content.token
}

$base_uri = $basepath + "/config/servers/trusted-master-servers"


$response_getAll = Invoke-WebRequest `
               -Uri $base_uri `
               -Method GET `
               -ContentType $contentType `
               -Headers $headers

if ($response_getAll.StatusCode -ne 200)
{
    throw "Unable to fetch trusted master server list." 
}

Write-Host "Trusted master server list fetched successfully.`n"
Write-Host $response_getAll

$response_getAll = (ConvertFrom-Json -InputObject $response_getAll)