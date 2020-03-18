<#

.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for setting replication target at disk volume for msdp.

.DESCRIPTION
This script will add replication target at disk volume level for msdp

.EXAMPLE
./Post-NB-add-replication-target-to-disk-volume.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -stsid "storage server id" -dvid "diskvolume id"
#>

param (
    [string]$nbmaster    = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),
    [string]$username    = $(throw "Please specify the user name using -username parameter."),
    [string]$password    = $(throw "Please specify the password using -password parameter.")
    [string]$stsid       = $(throw "Please specify the storage server identifier using -stsid parameter.")
    [string]$dvid        = $(throw "Please specify the diskvolume id using -dvid parameter.")
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
    }G
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
$content_type3 = "application/vnd.netbackup+json;version=3.0"

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
# POST Add replication target on disk volume level with specified details.
#####################################################################

$headers = @{
  "Authorization" = $content.token
}

$sts_uri = $basepath + "/storage/storage-servers" + $stsid + "/disk-volumes/" + dvid + "/replication-targets"

$json = '{
{
  "data": {
    "type": "volumeReplicationTarget",
    "attributes": {
      "operationType": "SET_REPLICATION",
      "targetVolumeName": "DISK_VOLUME_NAME",
      "targetStorageServerDetails": {
        "masterServerName": "TARGET_MASTER_SERVER",
        "mediaServerName": "TARGET_MEDIA_SERVER",
        "storageServerName": "TARGET_STORAGE_SERVER_NAME",
        "storageServerType": "TARGET_STORAGE_SERVER_TYPE",
                "credentials": {
          "userName": "TARGET_USERID",
          "password": "TARGET_PASSWORD"
        }
      }
    }
  }
}
}
'

$response_add_replication_target_on_dv = Invoke-WebRequest             `
                    -Uri $sts_uri                `
                    -Method POST                 `
                    -Body ($json)        `
                    -ContentType $content_type3  `
                    -Headers $headers

if ($response_add_replication_target_on_dv.StatusCode -ne 204)
{
    throw "Unable to set replication target." 
}

Write-Host "Replication target on with the specified details on disk volume is added successfully.`n"
echo $response_add_replication_target_on_dv
Write-Host $response_add_replication_target_on_dv

$response_add_replication_target_on_dv = (ConvertFrom-Json -InputObject $response_create_sts)
