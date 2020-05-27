<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for listing the jobs.
.DESCRIPTION
This script will get a list of netbackup jobs and print the details of the last 10 jobs in a tabular format.
.EXAMPLE
./Get-NB-PolicyDetails.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -nbpolicy "policy_name"
#>

param (

    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$username = $(throw "Please specify the user name using -username parameter."),
    [string]$password = $(throw "Please specify the password using -password parameter."),
    [string]$nbpolicy = $(throw "Please specify the password using -password parameter.")

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
# Get the detais for a named policy...
#####################################################################

$uri = $basepath + "/config/policies/" + $nbpolicy

$headers = @{
  "Authorization" = $content.token
  "X-NetBackup-Policy-Use-Generic-Schema" = $true
}

$query_params = @{}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the policy details for $nbpolicy!"
}

$content = (ConvertFrom-Json -InputObject $response)


# This prints the majority of policies attributes...
$content.data.attributes.policy.policyAttributes

# This prints the policy client list...
#$content.data.attributes.policy.clients.hostname

# This prints the backup selections...
#$content.data.attributes.policy.backupSelections.selections
