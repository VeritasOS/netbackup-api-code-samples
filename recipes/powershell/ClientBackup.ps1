<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for launching a manual backup from a Windows client system
.DESCRIPTION
This script will query the master server for policy information and existing client backup images.  If the latest full backup
is older than the frequency defined within the policy schedule a full backup will be launched; otherwise, an incremental will
be performed.
.EXAMPLE
.\ClientBackup.ps1 -p "ExampleClientBackup-Win" -k "AybRCz3UE_YOpCFD7_5mzQQfJsRXj_pN6WXLA7boX4EAuKD_kwBfXWQ5bFNWDiuJ"
#>

<#
Requirements and comments for running this script
* Tested with PowerShell 5.1 but should work with PowerSell 3.0 or later
* Tested with NetBackup 8.3
* NetBackup client software already installed, configured and tested
* A policy must be defined on the master server with the following details
    * Policy type must be MS-Windows
    * At least 2 schedules define with no backup windows
        * one full
        * one incremental
    * Client name added to Clients tab
* Use command line parameters to specify the following parameters
    * -policy (to reference above policy)
    * -apikey (generated through NetBackup web UI)
* API key uesr must have following privileges assigned to it's role:
    * Minimum specific privileges:  
        * Global -> NetBackup management -> NetBackup images -> View
        * Global -> Protection -> Policies -> View
        * Global -> Protection -> Policies -> Manual Backup
* PowerShell Execution Policy needs to be opened
#>


param (
    [string]$p = $(throw "Please speicfy the policy name using -p parameter."),
    [string]$k = $(throw "Please specify the password using -k parameter."),
    [switch]$v = $false,
    [switch]$t = $false
)
$policy=$p
$apikey=$k
$verbose=$v
$testmode=$t

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

#####################################################################
# Looking in the registry for NetBackup details
#####################################################################
$a = Get-ItemPropertyValue -path HKLM:\SOFTWARE\VERITAS\NetBackup\CurrentVersion\Config -name Server
$b = $a.Split(" ")
if ( $b -is [system.array] ) {
    $nbmaster=$b[0]
} else {
    $nbmaster=$b
}
$clientname = Get-ItemPropertyValue -path HKLM:\SOFTWARE\VERITAS\NetBackup\CurrentVersion\Config -name Client_Name

if ( $verbose ) {
    Write-Host "Looking at local NetBackup configuration for client name and master server"
    Write-Host "nbmaster=$nbmaster"
    Write-Host "clientname=$clientname"
    Write-Host
}

#####################################################################
# Global Variables
#####################################################################
$port = 1556
$basepath = "https://" + $nbmaster + ":" + $port + "/netbackup"
$content_type = "application/vnd.netbackup+json;version=4.0"
$days2lookback = 30
if ( $verbose ) {
    Write-Host "Base URI = $basepath"
    Write-Host "Looking back $days2lookback days for previous backups"
    Write-Host
}

#####################################################################
# Getting the policy details
#####################################################################
$uri = $basepath + "/config/policies/"+$policy
if ( $verbose ) {
    Write-Host "Getting $policy policy details"
    Write-Host "Using URI $uri"
}

$headers = @{
   "Authorization" = $apikey
   "X-NetBackup-Policy-Use-Generic-Schema" = "true"
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the list of Netbackup images!"
}

# Converting JSON output into PowerShell object format
$content = (ConvertFrom-Json -InputObject $response)

# Determining backup frequency for full backup and getting
# the full and incr schedule names
for ( $i=0; $i -lt $content.data.attributes.policy.schedules.count; $i++ ) {
    if ( $content.data.attributes.policy.schedules[$i].schedulename -eq "FULL" ) {
        $fullfrequency = $content.data.attributes.policy.schedules[$i].frequencyseconds
        $fullschedule = $content.data.attributes.policy.schedules[$i].schedulename
    }
    if ( $content.data.attributes.policy.schedules[$i].schedulename -like "INCR" ) {
        $incrfrequency = $content.data.attributes.policy.schedules[$i].frequencyseconds
        $incrschedule = $content.data.attributes.policy.schedules[$i].schedulename
    }
}

if ( $verbose ) {
    Write-Host "Incremental schedule $incrschedule frequency is $incrfrequency seconds"
    Write-Host "Full schedule $fullschedule frequency is $fullfrequency seconds"
    Write-Host
}

#####################################################################
# Get NetBackup Images from last days2lookback (30 default) days for this client
#####################################################################
$uri = $basepath + "/catalog/images"
if ( $verbose ) {
    Write-Host "Looking for most recent backup images to see what kind of backup to run"
    Write-Host "Using URI $uri "
}

$headers = @{
    "Authorization" = $apikey
}

# Note that currentDate and lookbackDate are DateTime objects while
# backupTimeStart and backupTimeEnd are string date in ISO 8601 format
# using Zulu (Greenwich Mean Time) time:  YYYY-MM-DDThh:mm:ssZ
# Date/Time format example:  November 13, 1967 at 3:22:00 PM = 1967-11-13T15:22:00Z
# Getting current date
$a = Get-Date
$currentDate=$a.ToUniversalTime()
$backupTimeEnd = (Get-Date -format s -date $currentDate) + "Z"

# Set starting date to 30 days from current date
$lookbackDate = (Get-Date).AddDays(-$days2lookback)
$backupTimeStart = (Get-Date -format s -date $lookbackDate) + "Z"

$query_params = @{
  "page[limit]" = 50 # This changes the default page size to 50
  # The following filter variable adds a filter to only show for this client in past 30 days
  #"filter" = "clientName eq '$clientname' and backupTime ge $backupTimeStart and backupTime le $backupTimeEnd"
  "filter" = "clientName eq '$clientname'"
}
if ( $verbose ) {
    Write-Host "backupTimeEnd   = $backupTimeEnd"
    Write-Host "backupTimeStart = $backupTimeStart"
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -Body $query_params           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the list of Netbackup images!"
}

#Write-Host "response=$response"
#Write-Host "Response JSON"
#$response | ConvertFrom-Json | ConvertTo-Json

# Convert the JSON output into PowerShell object format
$content = (ConvertFrom-Json -InputObject $response)

# Converting the JSON data for the image attributes into an array for looping through
$imageinfo = %{$content.data.attributes}
#Write-Host "Image info JSON"
#$imageinfo | ConvertTo-Json
#Get-Member -InputObject $imageinfo

# Setting values to validation variables
$schedulerun = "none"
$fulltime = "no"
$incrtime = "no"

# Looping through all the images found for this client looking for most recent
# full and incr backup image.  Image data is listed in date descending order, i.e.,
# newest to oldest.  We just need to capture the first instance of either backup type
# Handling 3 scenarios of returned images counts:
# 1 image doesn't create an array of objects so need to process
# 2 or more images create array of objects to process in a loop
if ( $content.meta.pagination.count -eq 1 ) {
    if ( $imageinfo.scheduleName -eq "FULL" ) {
        $fulltime= [datetime]::Parse($imageinfo.backuptime)
    } else {
        $incrtime= [datetime]::Parse($imageinfo.backuptime)
    }
} else {
    for ( $i=0; $i -lt $content.meta.pagination.count; $i++ ) {
        # Can skip if we've identified that we don't need to run any backups
        if ( $fulltime -ne "no" -AND $incrtime -ne "no" ) {
            continue
        } elseif ( $imageinfo[$i].scheduleName -eq "FULL" ) {
            $fulltime = [datetime]::Parse($imageinfo[$i].backuptime)
        } elseif ( $imageinfo[$i].scheduleName -eq "INCR" ) {
            $incrtime = [datetime]::Parse($imageinfo[$i].backuptime)
        }
    }
}

# Define the full and incr window by subtracting the schedule frequency from
#   the current time.
$fullwindow=$currentDate.AddSeconds(-$fullfrequency)
$incrwindow=$currentDate.AddSeconds(-$incrfrequency)

# Now, run through the logic to determine what kind of backup to run
if ( $fulltime -eq "no" ) {
    # No recent backup images found for this client, run full backup
    $schedulerun = "FULL"
} elseif ( $fullwindow -ge $fulltime ) {
    # Found a FULL backup older than current full window
    $schedulerun = "FULL"
} elseif ( $fulltime -ne "no" -AND $incrtime -eq "no" ) {
    # Full backup found but less than window and no incremental
    $schedulerun = "INCR"
} elseif ( $incrwindow -ge $incrtime ) {
    # Full backup less than window and incremental older than window
    $schedulerun = "INCR"
} else {
    $schedulerun = "none"
}

if ( $verbose ) {
    Write-Host "schedulerun=$schedulerun"
    Write-Host "fulltime=$fulltime"
    Write-Host "incrtime=$incrtime"
    Write-Host "fullwindow=$fullwindow"
    Write-Host "incrwindow=$incrwindow"
}

# If schedulerun is equal to none, then skip running anything
if ( $schedulerun -eq "none" ) {
    Write-Host "Too soon to take a backup"
    exit
}

# Running this in testing mode which means we don't want to run a backup,
# just see what wwould be run
if ( $testmode ) {
    exit
}

#####################################################################
# Launch the backup now
#####################################################################
$uri = $basepath + "/admin/manual-backup"
if ( $verbose ) {
    Write-Host "Launching the backup now"
    Write-Host "Using URI $uri"
}

$headers = @{
   "Authorization" = $apikey
}

$backup_params = @{
    data = @{
        type = "backupRequest"
        attributes = @{
            policyName = $policy
            scheduleName = $schedulerun
            clientName = $clientname
        }
    }
}

$body = ConvertTo-Json -InputObject $backup_params

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method POST                   `
                -Body $body           `
                -ContentType $content_type    `
                -Headers $headers

if ($response.StatusCode -ne 202)
{
    # Backup job did not start successfully
    "API StatusCode = "+$response.StatusCode
    #Write-Host $response.errorResponse
    #$content = (ConvertFrom-Json -InputObject $response)
    #"NetBackup error code = "+$content.errorResponse.errorCode
    #"NetBackup error message ="+$content.errorResponse.errorMessage
    throw "Unable to start the backup for "+$clientname+" with schedule "+$schedulerun+" for policy "+$policy
}

if ( $verbose ) {
    Write-Host "Backup $schedulerun successfully started"
}