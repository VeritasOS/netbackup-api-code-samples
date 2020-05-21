<#

.SYNOPSIS
This sample script demonstrates the use of NetBackup REST API for searching assets
based on a search criteria and delete those assets returned from the search.

.DESCRIPTION
This script will get a list of asset in the AssetDB that matches the data filter and
delete those assets. However, the asset only gets deleted if there is not subscription
associated to the asset, and the last discovered time of the asset is older than the given
cleanupTime.

.EXAMPLE
./Post-NB-Cleanup-Assets.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -filter "workloadType eq 'VMware'" -cleanuptime "2018-06-29T15:58:45.678Z"

#>

param (
    [string]$nbmaster    = $(throw "Please specify the name of NetBackup master server using -nbmaster parameter."),    
    [string]$username    = $(throw "Please specify the user name using -username parameter."),
    [string]$password    = $(throw "Please specify the password using -password parameter."),
    [string]$filter      = $(throw "Please specify the filter using -filter paramter"),
    [string]$cleanuptime = $(throw "Please specify the cleanuptime using -cleanuptime paramter")
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
$content_type1 = "application/vnd.netbackup+json;version=1.0"
$content_type2 = "application/vnd.netbackup+json;version=2.0"

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

$content = (ConvertFrom-Json -InputObject $response)

#####################################################################
# Get NetBackup Assets
#####################################################################

$uri = $basepath + "/assets?filter=" + $filter

$headers = @{
  "Authorization" = $content.token
}

$response = Invoke-WebRequest                 `
                -Uri $uri                     `
                -Method GET                   `
                -ContentType $content_type2   `
                -Headers $headers

if ($response.StatusCode -ne 200)
{
    throw "Unable to get the list of Netbackup Assets!"
}

$content_get = (ConvertFrom-Json -InputObject $response)

if (!$content_get.data){
    echo ""
    echo "Your filter: $filter did not return any asset."
    echo ""
} else {
    echo ""
    echo ""
    echo "These are the assets returned by your filter:"
    echo ""

    # This prints all the available attributes
    #$content_get.data.attributes | Format-Table -AutoSize

    $properties = 
        @{Label = "Asset ID"; Expression = { $_.id }},
        @{Label = "ProviderGeneratedId";   Expression = { $_.attributes.providerGeneratedId }},
        @{Label = "DisplayName";  Expression = { $_.attributes.displayName }},
        @{Label = "AssetType"; Expression = { $_.attributes.assetType }},
        @{Label = "WorkloadType"; Expression = { $_.attributes.workloadType }}
 
    $content_get.data | Format-Table -AutoSize -Property $properties

    # Prepara payload for the Asset Cleanup API call
    $assetIds = $content_get.data.id -join '","'
    $assetIds = '"' + $assetIds + '"'

    $body_cleanupRequest = '{"data":{
    "type":"assetCleanup", "id":"id",
    "attributes":{
    "cleanupTime":"' + $cleanupTime + '",
    "assetIds":[' + $assetIds + ']}}}'

#####################################################################
# Delete NetBackup Assets
#####################################################################

    $cleanup_uri = $basepath + "/assets/asset-cleanup"

    $response_delete = Invoke-WebRequest         `
                    -Uri $cleanup_uri            `
                    -Method POST                 `
                    -Body ($body_cleanupRequest) `
                    -ContentType $content_type2  `
				    -Headers $headers

    if ($response_delete.StatusCode -ne 204)
    {
        throw "Unable to delete Assets " + $assetIds
    }
}
