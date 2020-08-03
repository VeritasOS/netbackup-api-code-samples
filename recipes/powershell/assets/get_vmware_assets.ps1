<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup APIs for retieving VMware plugin information.
.DESCRIPTION
This script can be run using NetBackup 8.3 and higher.
It retrieves VMware asset data
.EXAMPLE
./get_VMware_Asset_Data.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>][-assetsFilter <filter>]
#>

#Requires -Version 4.0

Param (
    [string]$MasterServer = $(Throw "Please specify the name of the NetBackup Master Server using the -MasterServer parameter."),
    [string]$username = $(Throw "Please specify the user name using the -username parameter."),
    [string]$password = $(Throw "Please specify the password using the -password parameter."),
    [string]$domainName,
    [string]$domainType,
    [string]$assetsFilter
)

####################
# Global Variables
####################

$port = 1556
$baseUri = "https://" + $MasterServer + ":" + $port + "/netbackup/"
$assetServiceUri = "asset-service/workloads/vmware/assets?";
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
# GET Assets
#################################################
Function getAssets()
{
    $uri = $baseUri + $assetServiceUri

    $default_sort = "sort=commonAssetAttributes.displayName"

    if($assetsFilter -eq "" -Or $assetsFilter -eq "vm"){
        $assetTypeFilter = "filter=assetType eq 'vm'"
    }
    elseif($assetsFilter -eq "vmGroup"){
         $assetTypeFilter = "filter=assetType eq 'vmGroup'"
    }
    else{
        $assetTypeFilter = $assetFilter
    }

    $offset = 0
    $next = $true

    while ($next){
        $uri = $baseUri + $assetServiceUri + $assetTypeFilter + "&" + $default_sort + "&page[offset]=$offset"

        Write-Host "`nSending a GET request to list all Assets...`n"

        $response = Invoke-WebRequest `
                    -Uri $uri `
                    -Method GET `
                    -ContentType $contentType `
                    -Headers $headers

        if ($response.StatusCode -ne 200)
        {
            throw "Unable to get VMware assets.`n"
        }

        $api_response = (ConvertFrom-Json -InputObject $response)

        if($assetsFilter -eq "" -Or $assetsFilter -eq "vm"){
            $vm_data = 
                @{Label = "DisplayName"; Expression = { $_.attributes.commonAssetAttributes.displayName}},
                @{Label = "InstanceUUID"; Expression = { $_.attributes.instanceUuid }},
                @{Label = "vCenter"; Expression = { $_.attributes.vCenter }},
                @{Label = "Asset Protection Plans"; Expression = { $_.attributes.commonAssetAttributes.activeProtection.protectionDetailsList }}

           $api_response.data | Format-Table -AutoSize -Property $vm_data

        }
        elseif($assetsFilter -eq "vmGroup"){
            $vmGroup_data = 
                @{Label = "DisplayName"; Expression = { $_.attributes.commonAssetAttributes.displayName}},
                @{Label = "filterConstraint"; Expression = { $_.attributes.filterConstraint }}, 
                @{Label = "oDataQueryFilter"; Expression = { $_.attributes.oDataQueryFilter }},
                @{Label = "Asset Protection Plans"; Expression = { $_.attributes.commonAssetAttributes.activeProtection.protectionDetailsList }}

            $api_response.data | Format-Table -AutoSize -Property $vmGroup_data
        }

        if($api_response.meta.pagination.hasNext -eq "false"){
            $next = $false
        }
    }
}

Setup
$loginResponse = Login
$headers = @{"Authorization" = $loginResponse.token}
getAssets