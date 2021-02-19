<#
.SYNOPSIS
Setup NetBackup Env.
.DESCRIPTION
Sets up the Netbackup api enviornment for the parent script.   Will set nbcontent_type that is used in other functions for other calls
.EXAMPLE
Set-NbInitialSetup
.OUTPUTS
Sets nbcontent_type Variable
.NOTES
FunctionName : Set-NbInitialSetup
Created by   : Nick Britton
#>

#####################################################################
# Initial Setup
# Note: This allows self-signed certificates and enables TLS v1.2
#####################################################################

function Set-NbInitialSetup()
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

    # Force TLS v1.2
    try {
        if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12') {
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Host $_.Exception.InnerException.Message
    }
  }
  # Global Variables
  $script:nbcontent_type = "application/vnd.netbackup+json;version=4.0"

}
