<#
# .SYNOPSIS
# This sample script reads a JSON data file to get a list of failed backup
# jobs from the primary servers.
#
# .DESCRIPTION
# This script will read the JSON data file to get a list of NetBackup primary
# servers with valid API keys.  For each primary server, the "GET /admin/jobs"
# API will be executed with a filter to get just failed jobs.
#
# .EXAMPLE
# ./cli_failed_jobs.py3 [ -v ]
#
# Requirements and comments for running this script
#    Tested with PowerShell 5.1
#    Tested with NetBackup 9.1
#    API key uesr must have following minimum  privileges assigned to it's role:
#        Manage -> Jobs -> View
#>

#####################################################################
# Getting the various command line parameters
#####################################################################
param (
    [switch]$v = $false
)
$verbose=$v

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
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Host $_.Exception.InnerException.Message
    }
  }
}

InitialSetup

################################################################
# Setting some variables to be used through the rest of the processing
################################################################
$primary_file = "primary_servers.json"
$page_limit=100 # 100 is maxium number to retreive at a time
$content_type = "application/vnd.netbackup+json;version=6.0"
if ( $verbose ) {
    Write-Host "Using $primary_file for server and API keys"
    Write-Host "Collecting $page_limit jobs at a time"
    Write-Host
}

################################################################
# Reading the primary_servers.json file to get list of
# NBU primary servers and API keys to use for authorization
################################################################
if ( -not (Test-Path -Path $primary_file -PathType Leaf)) {
    throw "Specified file $primary_file does not exist"
}

$primary_data = Get-Content -Raw -Path $primary_file | ConvertFrom-Json

################################################################
# Loop through all the primary servers getting a list of
# failed jobs
################################################################
$table = @("Master       JobID   Status  Type     Client          Policy               Schedule")
foreach ( $data in $primary_data.primaryServers ) {
    if ( $verbose ) {
        Write-Host "Getting job data from"$data.name"with"$data.apikey
    }

    ####################################
    # Build out the HTTP request details
    $uri = "https://" + $data.name + "/netbackup/admin/jobs/"
    $query_params= @{
        "page[limit]" = $page_limit
        "filter" = "status gt 0 and state eq 'DONE' and jobType eq 'BACKUP'"
        "sort" = "-jobId" # Sorting by job ID in descending order
    }
    $header = @{
        "Authorization" = $data.apikey
        "Accept" = $content_type
    }
    if ( $verbose ) {
        Write-Host "Getting list of jobs from $data.name"
        Write-Host "User URI $uri"
    }

    ####################################
    # Make the job API call
    $response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $header

    if ($response.StatusCode -ne 200) {
        Write-Host "Unable to get the list of Netbackup jobs!"
        throw "API status code = "+$response.StatusCode
    }

    ####################################
    # Collecting data into table array
    $job_data=(ConvertFrom-Json -InputObject $response)
    
    if ( $job_data.data -eq $null ) {
        $table+="No failed backup jobs found for $data.name"
        continue
    } else {
        foreach ($job in $job_data.data) {
            $line=($data.name).subString(0,12)+" "
            $line+=(($job.attributes.jobId).ToString()).PadRight(7," ")+" "
            $line+=(($job.attributes.status).ToString()).PadRight(7," ")+" "
            $line+=($job.attributes.jobType).PadRight(8," ")+" "
            $line+=(($job.attributes.clientName).PadRight(15," ")).subString(0,15)+" "
            $line+=(($job.attributes.policyName).PadRight(20," ")).subString(0,20)+" "
            $line+=(($job.attributes.scheduleName).PadRight(20," ")).subString(0,20)+" "
            $table+=$line
        }
    }

    # If the first call to jobs generates more data than page_limit,
    # then loop through until finished collecting all the pages of jobs
    if ( $job_data.links.next -ne $null ) {
        ####################################
        # Getting the next page URI
        $next_uri=$job_data.links.next.href

        while ($true) {
            ####################################
            # Make the job API call
            ####################################
            # Make the job API call
            $response = Invoke-WebRequest                 `
                        -Uri $next_uri                     `
                        -Method GET                   `
                        -ContentType $content_type    `
                        -Headers $header

            if ($response.StatusCode -ne 200) {
                Write-Host "Unable to get the list of Netbackup jobs!"
                throw "API status code = "+$response.StatusCode
            }
                        
            ####################################
            # Add information to policy_dict
            $job_data=(ConvertFrom-Json -InputObject $response)
            foreach ($job in $job_data.data) {
                $line=($data.name).subString(0,12)+" "
                $line+=(($job.attributes.jobId).ToString()).PadRight(7," ")+" "
                $line+=(($job.attributes.status).ToString()).PadRight(7," ")+" "
                $line+=($job.attributes.jobType).PadRight(8," ")+" "
                $line+=(($job.attributes.clientName).PadRight(15," ")).subString(0,15)+" "
                $line+=(($job.attributes.policyName).PadRight(20," ")).subString(0,20)+" "
                $line+=(($job.attributes.scheduleName).PadRight(20," ")).subString(0,20)+" "
                $table+=$line
            }

            ####################################
            # Break out of the pagination loop
            # if there is no next href page
            if ( $job_data.links.next -ne $null) {
                $next_uri=$job_data.links.next.href
            } else {
                break
            }
        }
    }
}

##################################
# Finally output the built table with all the job information
##################################
$table | Format-Table -AutoSize