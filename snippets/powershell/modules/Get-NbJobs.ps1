<#
.SYNOPSIS
Get NetBackup Jobs from master server.
.DESCRIPTION
Gets the list of jobs from the master server.
See https://Masterserver:1556/api-docs/index.html?urls.primaryName=admin#/Jobs/get_admin_jobs for details on the api used.
.PARAMETER filter
The odata filter to apply.   See link above for details.  Ex. "policyType eq '$policyType' and jobId ne parentJobId"
.PARAMETER pagelimit
Limit the number of records per page
.EXAMPLE
Get-NbJobs -filter policyType eq policyType and jobId ne parentJobId -pagelimit 99
.OUTPUTS
Array
.NOTES
FunctionName : Get-NbJobs
Created by   : Nick Britton
#>

function Get-NbJobs()
{
[CmdletBinding()]
param (
        [Parameter(Mandatory=$false,
                   HelpMessage="Filter in odata format.  Ex. policyType eq policyType and jobId ne parentJobId")]
        [string]$filter,
        [Parameter(Mandatory=$false,
                   HelpMessage="Page limit 0-99")]
        [string]$pagelimit
     )
$uri = $basepath + "/admin/jobs"

$query_params = @{
                "filter" = "$filter"     # This adds a filter to only show the restore jobs
                "page[limit]" = "$pagelimit"

                 }

$response = Invoke-WebRequest -Uri $uri -Method GET -Body $query_params -ContentType $nbcontent_type -Headers $nbheaders

if ($response.StatusCode -ne 200) {    throw "Unable to get the Netbackup jobs!"}

$content = (ConvertFrom-Json -InputObject $response)


$jobarray = $content.data
Return $jobarray

}
