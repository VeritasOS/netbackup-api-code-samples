<#
.SYNOPSIS
Get client or host details from master server
.DESCRIPTION
Gets the host details for each client on the master and will return the details in an array.
See https://Masterserver:1556/api-docs/index.html?urls.primaryName=config#/Hosts/get_config_hosts for details on the api used.
.EXAMPLE
Get-NbClientInfo
.OUTPUTS
Array
.NOTES
FunctionName : Get-NbDiscoveryStatus
Created by   : Nick Britton
#>

function Get-NbVMDiscoveryStatus()
{
$uri = $basepath + "/admin/discovery/workloads/vmware/status"
$query_params = @{
                "page[limit]" = "99"

                 }
$response = Invoke-WebRequest -Uri $uri -Method GET -Body $query_params -ContentType $nbcontent_type -Headers $nbheaders
if ($response.StatusCode -ne 200){ throw "Unable to get the client details"}
$content = (ConvertFrom-Json -InputObject $response)
$data = $content.data

$properties = 
    @{Label = "vcenter"; Expression = { $_.attributes.ServerName }},
    @{Label = "workload"; Expression = { $_.attributes.WorkloadType }},
    @{Label = "Status"; Expression = { $_.attributes.discoveryStatus }},
    @{Label = "StartTime"; Expression = { $_.attributes.discoveryStartTime }},
    @{Label = "EndTime"; Expression = { $_.attributes.discoveryFinishTime }},
    @{Label = "ModifyTime"; Expression = { $_.attributes.lastModifiedDateTime }},
    @{Label = "DiscoveryHost";  Expression = { $_.attributes.additionalAttributes.discoveryHost }},
    @{Label = "DiscoveryFreq";  Expression = { $_.attributes.additionalAttributes.discoveryFrequencySeconds }},
    @{Label = "DiscoveryDisabled"; Expression = { $_.attributes.additionalAttributes.isDiscoveryDisabled }}

    $data = $data|Select-Object -Property $properties
Return $data
}
