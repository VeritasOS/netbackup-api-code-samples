<#
.SYNOPSIS
Get NetBackup Jobs from master server.
.DESCRIPTION
Gets the list of jobs from the master server.
See https://Masterserver:1556/api-docs/index.html?
.PARAMETER assetType
The ability to filter vms or vmgroups
.EXAMPLE
Get-NbAssets -assetType vm or vmGroup 
.OUTPUTS
Array
.NOTES
FunctionName : Get-NbAssets
Created by   : Nick Britton
#>

function Get-NbAssets()
{
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true,
                   HelpMessage="AssetType needs to specifiy vm or vmGroup")]
        [string]$assetType
        
     )
    $assetType = "vm"
 # FUNCTION START
    $results = @()
    $uri = $basepath + $assetServiceUri

    $default_sort = "commonAssetAttributes.displayName"

    if($assetType -eq  "vm"){
        $assetTypeFilter = "assetType eq 'vm'" 
    }
    elseif($assetType -eq "vmGroup"){
         $assetTypeFilter = "assetType eq 'vmGroup'"
    }
    $offset = 0
    $next = $true

    while ($next){
       
       $assetServiceUri = "/asset-service/workloads/vmware/assets"
       $uri = $basepath + $assetServiceUri
       $query_params = @{
                "filter" = "$assetTypeFilter"
                "sort" = "commonAssetAttributes.displayName"
                "page[offset]" = "$offset"
                "page[limit]" = "100"
                 }
        
        $response = Invoke-WebRequest -Uri $uri -Method GET -Body $query_params -ContentType $nbcontent_type -Headers $nbheaders

            if ($response.StatusCode -ne 200) { throw "Unable to get VMware assets.`n"  }

        $api_response = (ConvertFrom-Json -InputObject $response)

        $results += $api_response
        #write-host "offset is $offset"
        $offset = $offset + $api_response.meta.pagination.limit
            if($api_response.meta.pagination.hasNext -eq $false){ $next = $false }

    }
$assetarray = $results.data
Return $assetarray
}