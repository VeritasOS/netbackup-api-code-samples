<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Policy REST APIs.
.DESCRIPTION
This script can be run using NetBackup 8.1.2 and higher.
It creates a policy with the default values for policy type specific attributes, adds a client, schedule, and backup selection to it, then deletes the client, schedule and finally deletes the policy.
.EXAMPLE
./New-Policy-StepByStep.ps1 -MasterServer "nb-master.example.com" -UserName "administrator" -Password "password" -DomainName "domain name"
#>

#Requires -Version 4.0

Param (
    [string]$MasterServer = $(Throw "Please specify the name of the NetBackup Master Server using the -MasterServer parameter."),
    [string]$UserName = $(Throw "Please specify the user name using the -UserName parameter."),
    [string]$Password = $(Throw "Please specify the password using the -Password parameter."),
    [string]$DomainName,
    [string]$DomainType
)

####################
# Global Variables
####################

$port = 1556
$basePath = "https://" + $MasterServer + ":" + $port + "/netbackup"
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
        Add-Type -TypeDefinition
@"
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
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
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
    $uri = $basepath + "/login"

    $body = @{
        userName=$UserName
        password=$Password
    }
    if ($DomainName -ne "") {
        $body.add("domainName", $DomainName)
    }
    if ($DomainType -ne "") {
        $body.add("domainType", $DomainType)
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
# Create a policy with default attribute values
#################################################
Function CreatePolicyWithDefaults()
{
    $uri = $basepath + "/config/policies"

    $policy = @{
        policyName=$testPolicyName
        policyType="VMware"
        policyAttributes=@{}
        clients=@()
        schedules=@()
        backupSelections=@{selections=@()}
    }

    $data = @{
        type="policy"
        id=$testPolicyName
        attributes=@{policy=$policy}
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 5

    Write-Host "`nSending a POST request to create $testPolicyName with defaults..."
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
    $uri = $basepath + "/config/policies"

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
    $uri = $basepath + "/config/policies/" + $testPolicyName

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
    $uri = $basepath + "/config/policies/" + $testPolicyName

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

############################
# Add a client to a policy
############################
Function AddClient()
{
    $uri = $basepath + "/config/policies/" + $testPolicyName + "/clients/" + $testClientName

    $data = @{
        type="client"
        attributes=@{
            hardware="VMware"
            hostName="MEDIA_SERVER"
            OS="VMware"
        }
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 3

    Write-Host "`nSending a PUT request to add client $testClientName to policy $testPolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method PUT `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 201)
    {
        throw "Unable to add  client $testClientName to policy $testPolicyName.`n"
    }

    Write-Host "$testClientName added to $testPolicyName successfully.`n"
}

#################################
# Delete a client from a policy
#################################
Function DeleteClient()
{
    $uri = $basepath + "/config/policies/" + $testPolicyName + "/clients/" +  $testClientName

    Write-Host "`nSending a DELETE request to delete client $testClientName from policy $testPolicyName..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete client $testClientName.`n"
    }

    Write-Host "$testClientName deleted successfully.`n"
}

######################################
# Add a backup selection to a policy
######################################
Function AddBackupSelection()
{
    $uri = $basepath + "/config/policies/" + $testPolicyName + "/backupselections"

    $data = @{
        type="backupSelection"
        attributes=@{
            selections=@("vmware:/?filter=Displayname Contains 'rsv' OR Displayname Contains 'mtv'")
        }
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 3

    Write-Host "`nSending a PUT request to add backupselection to policy $testPolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method PUT `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to add backupselection to policy $testPolicyName.`n"
    }

    Write-Host "backupselection added to $testPolicyName successfully.`n"
}

############################
# Add a schedule to policy
############################
Function AddSchedule()
{
    $uri = $basepath + "/config/policies/" + $testPolicyName + "/schedules/" + $testScheduleName

    $data = @{
        type="schedule"
        id=$testScheduleName
        attributes=@{
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
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 6
    Write-Host $body

    Write-Host "`nSending a PUT request to add schedule $testScheduleName to policy $testPolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method PUT `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 201)
    {
        throw "Unable to add schedule $testScheduleName to policy $testPolicyName.`n"
    }

    Write-Host "schedule $testScheduleName added to $testPolicyName successfully.`n"
}

###################################
# Delete a schedule from a policy
###################################
Function DeleteSchedule()
{
    $uri = $basepath + "/config/policies/" + $testPolicyName + "/schedules/" +  $testScheduleName

    Write-Host "`nSending a DELETE request to delete schedule $testScheduleName from policy $testPolicyName..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete schedule $testScheduleName.`n"
    }

    Write-Host "$testScheduleName deleted successfully.`n"
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
CreatePolicyWithDefaults
ListPolicies
ReadPolicy
AddClient
AddBackupSelection
AddSchedule
ReadPolicy
DeleteClient
DeleteSchedule
ReadPolicy
DeletePolicy
ListPolicies
