<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Policy REST APIs.
.DESCRIPTION
This script can be run using NetBackup 8.1.2 and higher.
It creates a policy with the default values for policy type specific attributes, adds a client, schedule, and backup selection to it in one step at the time of creating policy
.EXAMPLE
./create_policy_in_one_step.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>]
#>

#Requires -Version 4.0

Param (
    [string]$MasterServer = $(Throw "Please specify the name of the NetBackup Master Server using the -MasterServer parameter."),
    [string]$username = $(Throw "Please specify the user name using the -username parameter."),
    [string]$password = $(Throw "Please specify the password using the -password parameter."),
    [string]$domainName,
    [string]$domainType
)

####################
# Global Variables
####################

$port = 1556
$baseUri = "https://" + $MasterServer + ":" + $port + "/netbackup/"
$policiesUri = "config/policies/";
$contentType = "application/vnd.netbackup+json;version=2.0"
$testPolicyName = "vmware_test_policy"
$testClientName = "MEDIA_SERVER"
$testScheduleName = "vmware_test_schedule"

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

######################################
# Login to the NetBackup webservices
######################################

Function Login()
{
    $uri = $baseUri + "login"

    $body = @{
        userName=$username
        password=$password
    }
    if ($domainName -ne "") {
        $body.add("domainName", $domainName)
    }
    if ($domainType -ne "") {
        $body.add("domainType", $domainType)
    }
    Write-Host "`nSending a POST request to login to the NetBackup webservices..."

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
    $response = (ConvertFrom-Json -InputObject $response)
    return $response
}


#################################################
# Create a policy with default attribute values, but
# custom schedules, backupselections and clients
#################################################
Function CreatePolicy()
{
    $uri = $baseUri + $policiesUri

    $clients = @{
        hardware="VMware"
        hostName="MEDIA_SERVER"
        OS="VMware"
    }

    $backupSelections = "vmware:/?filter=Displayname Contains 'rsv' OR Displayname Contains 'mtv'"

    $schedules = @{
        scheduleName="sched-9-weeks"
        acceleratorForcedRescan=$false
        backupCopies=@{
            priority=9999
            copies=@(@{
                        mediaOwner="owner1"
                        storage=$null
                        retentionPeriod=@{
                                        value=9
                                        unit="WEEKS"
                        }
                        volumePool="NetBackup"
                        failStrategy="Continue"
                    }
            )
        }
        backupType="Full Backup"
        excludeDates=@{
                        lastDayOfMonth=$true
                        recurringDaysOfWeek=@("4:6", "2:5")
                        recurringDaysOfMonth=@(10)
                        specificDates=@("2000-1-1", "2016-2-30")
                    }
        frequencySeconds=4800
        includeDates=@{
                        lastDayOfMonth=$true
                        recurringDaysOfWeek=@("2:3", "3:4")
                        recurringDaysOfMonth=@(10,13)
                        specificDates=@("2016-12-31")
                    }
        mediaMultiplexing=2
        retriesAllowedAfterRunDay=$true
        scheduleType="Calendar"
        snapshotOnly=$false
        startWindow=@(@{dayOfWeek=1
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=2
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=3
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=4
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=5
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=6
                        startSeconds=14600
                        durationSeconds=24600},
                      @{dayOfWeek=7
                        startSeconds=14600
                        durationSeconds=24600}
        )
        syntheticBackup=$false
        storageIsSLP=$false
    }

    $policy = @{
        policyName=$testPolicyName
        policyType="VMware"
        policyAttributes=@{}
        clients=@($clients)
        schedules=@($schedules)
        backupSelections=@{selections=@($backupSelections)}
    }

    $data = @{
        type="policy"
        id=$testPolicyName
        attributes=@{policy=$policy}
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 9

    Write-Host "`nSending a POST request to create $testPolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method POST `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to create policy $testPolicyName."
    }

    Write-Host "$testPolicyName created successfully.`n"
    $response = (ConvertFrom-Json -InputObject $response)
}

#####################
# List all policies
#####################
Function ListPolicies()
{
    $uri = $baseUri + $policiesUri

    Write-Host "`nSending a GET request to list all policies...`n"
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method GET `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 200)
    {
        throw "Unable to list policies.`n"
    }

    Write-Host $response
}

#################
# Read a policy
#################
Function ReadPolicy()
{
    $uri = $baseUri + $policiesUri + $testPolicyName

    Write-Host "`nSending a GET request to read policy $testPolicyName...`n"
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method GET `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 200)
    {
        throw "Unable to read policy $testPolicyName.`n"
    }

    Write-Host $response
}

###################
# Delete a policy
###################
Function DeletePolicy()
{
    $uri = $baseUri + $policiesUri + $testPolicyName

    Write-Host "`nSending a DELETE request to delete policy $testPolicyName..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete policy $testPolicyName.`n"
    }

    Write-Host "$testPolicyName deleted successfully.`n"
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
CreatePolicy
ListPolicies
ReadPolicy
DeletePolicy
ListPolicies
