<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Storage management REST APIs.
.DESCRIPTION
This script can be run using NetBackup 8.2 and higher.
It demonstrate how to create a storage server, disk pool and storage unit by specifying json payload string in each specified function.
.EXAMPLE
./configure_storage_unit_end_to_end.ps1 -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>]
#>

#Requires -Version 4.0

Param (
    [string]$nbmaster = $(Throw "Please specify the name of the NetBackup Master Server using the -nbmaster parameter."),
    [string]$username = $(Throw "Please specify the user name using the -username parameter."),
    [string]$password = $(Throw "Please specify the password using the -password parameter."),
    [string]$domainName,
    [string]$domainType
)

####################
# Global Variables
####################

$port = 1556
$baseUri = "https://" + $nbmaster + ":" + $port + "/netbackup/"
$contentType = "application/vnd.netbackup+json;version=3.0"

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
# Create a cloud storage server
#################################################
Function CreateStorageServer()
{
    $sts_uri = $baseUri + "/storage/storage-servers"
    
    $sts_cloud_json = '{
       "data": {
          "type": "storageServer",
          "attributes": {
             "name": "amazonstss.com",
             "storageCategory": "CLOUD",
             "mediaServerDetails": {
                "name": "MEDIA_SERVER"
             },
             "cloudAttributes": {
                "providerId": "amazon",
    			"compressionEnabled": true,
                "s3RegionDetails": [
                   {
                      "serviceHost": "SERVICE-HOST",
                      "regionName": "REGION_NAME",
                      "regionId": "REGION_ID"
                   }
                ],
                "cloudCredentials": {
                   "authType": "ACCESS_KEY",
                   "accessKeyDetails": {
                      "userName": "USER_ID",
                      "password": "PASSWORD"
                   }
                }
             }
          }
       }
    }
    

    '
    
    $response_create_sts = Invoke-WebRequest             `
                        -Uri $sts_uri                `
                        -Method POST                 `
                        -Body ($sts_cloud_json)        `
                        -ContentType $contentType  `
                        -Headers $headers
    
    if ($response_create_sts.StatusCode -ne 201)
    {
        throw "Unable to create storage server." 
    }
    
    Write-Host "storage server created successfully.`n"
    echo $response_create_sts
    Write-Host $response_create_sts
    
    $response_create_sts = (ConvertFrom-Json -InputObject $response_create_sts)
}

#################################################
# Create a disk pool for cloud storage server
#################################################
Function CreateDiskPool()
{
    
    $dp_uri = $baseUri + "/storage/disk-pools"
    
    $dp_cloud_json = '{
        "data": {
            "type": "diskPool",
            "attributes": {
                "name": "disk-pool1",
                "diskVolumes": [
                    {
                        "name": "VOLUME_NAME"
                    }
                ],
                "maximumIoStreams": {
                    "limitIoStreams": true,
                    "streamsPerVolume": 4
                }
            },
            "relationships": {
                "storageServers": {
                    "data": [
                        {
                            "type": "storageServer",
                            "id": "STORAGE_SERVER_ID"
                        }
                    ]
                }
            }
        }
    }

    
    '
    
    $response_create_dp = Invoke-WebRequest             `
                        -Uri $dp_uri                `
                        -Method POST                 `
                        -Body ($dp_cloud_json)        `
                        -ContentType $contentType  `
                        -Headers $headers
    
    if ($response_create_dp.StatusCode -ne 201)
    {
        throw "Unable to create Disk Pool." 
    }
    
    Write-Host "Disk Pool created successfully.`n"
    echo $response_create_dp
    Write-Host $response_create_dp
    
    $response_create_dp = (ConvertFrom-Json -InputObject $response_create_dp)
}
	
####################################################################################
# Create a storage unit for cloud torage server
####################################################################################
Function CreateStorageUnit()
{
    $stu_uri = $baseUri + "/storage/storage-units"
    
    $stu_cloud_json = '{
      "data": {
        "type": "storageUnit",
        "attributes": {
          "name": "cloud-stu",
          "useAnyAvailableMediaServer": true,
          "maxFragmentSizeMegabytes": 50000,
          "maxConcurrentJobs": 10,
          "onDemandOnly": true
        },
        "relationships": {
            "diskPool": {
            "data" : {
                "type": "diskPool",
            	    "id": "STORAGE_SERVER_ID"
            	}
            }
        }
    }
    }
    '
    
    $response_create_stu = Invoke-WebRequest             `
                        -Uri $stu_uri                `
                        -Method POST                 `
                        -Body ($stu_cloud_json)        `
                        -ContentType $contentType  `
                        -Headers $headers
    
    if ($response_create_stu.StatusCode -ne 201)
    {
        throw "Unable to create storage unit." 
    }
    
    Write-Host "storage unit created successfully.`n"
    echo $response_create_stu
    Write-Host $response_create_stu
    
    $response_create_stu = (ConvertFrom-Json -InputObject $response_create_stu)
}

########################################################################
# List all Storage Servers
########################################################################
Function ListAllStorageServer()
{
    $sts_uri = $baseUri + "/storage/storage-servers"
    
    
    $response_getAll_sts = Invoke-WebRequest `
                   -Uri $sts_uri `
                   -Method GET `
                   -ContentType $contentType `
                   -Headers $headers
    
    if ($response_getAll_sts.StatusCode -ne 200)
    {
        throw "Unable to fetch storage servers." 
    }
    
    Write-Host "storage servers fetched successfully.`n"
    Write-Host $response_getAll_sts
    
    $response_getAll_sts = (ConvertFrom-Json -InputObject $response_getAll_sts)
}

###########################################################################
# List all Disk Pools
###########################################################################
Function ListAllDiskPools()
{ 
    $dp_uri = $baseUri + "/storage/disk-pools"
    
    
    $response_getAll_dp = Invoke-WebRequest `
                   -Uri $dp_uri `
                   -Method GET `
                   -ContentType $contentType `
                   -Headers $headers
    
    if ($response_getAll_dp.StatusCode -ne 200)
    {
        throw "Unable to fetch disk pools." 
    }
    
    Write-Host "disk pools fetched successfully.`n"
    Write-Host $response_getAll_dp
    
    $response_getAll_dp = (ConvertFrom-Json -InputObject $response_getAll_dp)
}

##############################################################################
# List all Storage Units
##############################################################################
Function ListAllStorageUnits()
{
    $stu_uri = $baseUri + "/storage/storage-units"
       
    $response_getAll_stu = Invoke-WebRequest `
                   -Uri $stu_uri `
                   -Method GET `
                   -ContentType $contentType `
                   -Headers $headers
    
    if ($response_getAll_stu.StatusCode -ne 200)
    {
        throw "Unable to fetch storage units." 
    }
    
    Write-Host "storage units fetched successfully.`n"
    Write-Host $response_getAll_stu
    
    $response_getAll_stu = (ConvertFrom-Json -InputObject $response_getAll_stu)
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
CreateStorageServer
ListAllStorageServer
CreateDiskPool
ListAllDiskPools
CreateStorageUnit
ListAllStorageUnits