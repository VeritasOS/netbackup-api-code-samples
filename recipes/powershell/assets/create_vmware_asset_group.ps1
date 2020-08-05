<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup APIs for creating VMware asset group
.DESCRIPTION
This script can be run using NetBackup 8.3 and higher.
It creates a VMware asset group
.EXAMPLE
./create_vmware_asset_group.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>]
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
$assetServiceUri = "asset-service/queries";
$contentType = "application/vnd.netbackup+json;version=4.0"


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
# Create Asset Group
#################################################
Function createAssetGroup()
{
    $uri = $baseUri + $assetServiceUri

    $assetGroupDataJson = '{
        "data": {
            "type": "query",
           "attributes": {
               "queryName": "create-or-update-assets",
               "workloads": ["vmware"],
               "parameters": {
                   "objectList": [
                   {
                       "correlationId": "corr-groupvcfdf",
                       "type": "vmwareGroupAsset",
                       "assetGroup": {
                           "description": "sampleDescription",
                           "assetType": "vmGroup",
                           "filterConstraint": "rsvlmvc01vm175.rmnus.sen.symantec.com",
                            "oDataQueryFilter": "true",
                            "commonAssetAttributes": {
                                "displayName": "sampleGroup249",
                                "workloadType": "vmware",
                                "protectionCapabilities": {
                                    "isProtectable": "YES",
                                    "isProtectableReason": "sampleReason",
                                    "isRecoverable": "NO",
                                    "isRecoverableReason": "sampleReason"
                                 },
                                 "detection": {
                                     "detectionMethod": "MANUAL"
                                 }
                            }
                        }
                    }
                    ]
                }
            }
        }
    }'

    Write-Host "Creating Asset Group.`n"

    $response_create_asset_group = Invoke-WebRequest `
                        -Uri $uri `
                        -Method POST `
                        -Body ($assetGroupDataJson) `
                        -ContentType $contentType `
                        -Headers $headers
    
    if ($response_create_asset_group.StatusCode -ne 201)
    {
        throw "Unable to create asset group." 
    }

    Write-Host "asset group created successfully.`n"
    echo $response_create_asset_group
    Write-Host $response_create_asset_group
    
    $response_create_stu = (ConvertFrom-Json -InputObject $response_create_asset_group)
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
createAssetGroup
