<#

.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for listing the jobs.

.DESCRIPTION
This script will get a list of netbackup jobs and print the details of the last 10 jobs in a tabular format.


.EXAMPLE
./Get-NB-Jobs.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret"

#>

param (
    [string]$nbmaster = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$username = $(throw "Please specify the user name using -username parameter."),
    [string]$password = $(throw "Please specify the password using -password parameter.")
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
$content_type = "application/vnd.netbackup+json;version=1.0"

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
# Get NetBackup Jobs
#####################################################################

$uri = $basepath + "/admin/jobs"

$headers = @{
  "Authorization" = $content.token
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
