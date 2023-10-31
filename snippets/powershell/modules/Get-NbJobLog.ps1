<#
.SYNOPSIS
Get NetBackup Job log for specified jobid from master server.
.DESCRIPTION
Gets the job log from the master server.
See https://Masterserver:1556/api-docs/index.html?urls.primaryName=admin#/Jobs/get_admin_jobs__jobId__try_logs for details on the api used.
The JobId can be found in the nbjobs function.
.PARAMETER jobid
JobId is required for the api call.
.EXAMPLE
Get-NbJobLog -jobid ######
.OUTPUTS
Array
.NOTES
FunctionName : Get-NbJobLog
Created by   : Nick Britton
#>

function Get-NbJobLog()
{
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true,
                   HelpMessage="Job id is required for api call")]
        [string]$jobid

     )

  $uri = $basepath + "/admin/jobs/$jobid/try-logs"
  $response = Invoke-WebRequest -Uri $uri -Method GET -ContentType $nbcontent_type -Headers $nbheaders

  if ($response.StatusCode -ne 200){throw "Unable to get the Netbackup jobs!"}
  $content = (ConvertFrom-Json -InputObject $response)
Return $content

}
