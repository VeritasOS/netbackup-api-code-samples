<#

.SYNOPSIS
This script demonstrates the usage of API key in netbackup REST API for listing the jobs

.DESCRIPTION
This script will get a list of netbackup jobs and print the details of the last 10 jobs in a tabular format.
The REST API triggered uses API key in 'Authorization' header instead of using JWT. This avoids the step of 
acquiring JWT after login to NetBackup.


.EXAMPLE
./APIKey-Usage.ps1 -nbmaster "nb-master.example.com" -apikey "apikey"
-nbmaster : Name of the NetBackup master server
-apikey : API key to be used instead of JWT

#>

param (
    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$apikey = $(throw "Please specify the api key using -apikey parameter.")
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
$content_type = "application/vnd.netbackup+json;version=3.0"

#####################################################################
# Get NetBackup Jobs
#####################################################################

$uri = $basepath + "/admin/jobs"

$headers = @{
  "Authorization" = $apikey
}

$query_params = @{
#  "page[limit]" = 100                   # This changes the default page size to 100
#  "filter" = "jobType eq 'RESTORE'"     # This adds a filter to only show the restore jobs
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the Netbackup jobs!"
}

$content = (ConvertFrom-Json -InputObject $response)

# This prints all the available attributes
#$content.data.attributes | Format-Table -AutoSize

$properties = 
    @{Label = "Job ID"; Expression = { $_.attributes.jobId }},
    @{Label = "Type";   Expression = { $_.attributes.jobType }},
    @{Label = "State";  Expression = { $_.attributes.state }},
    @{Label = "Status"; Expression = { $_.attributes.status }}

$content.data | Format-Table -AutoSize -Property $properties
