<#
.SYNOPSIS
This sample script demonstrates the use of NetBackup Policy REST APIs.
.DESCRIPTION
This script can be run using NetBackup 8.1.2 and higher.
.EXAMPLE
./rbac_filtering_in_policy.ps1 -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>]
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
$policiesUri = "config/policies/";
$contentType = "application/vnd.netbackup+json;version=2.0"
$testVMwarePolicyName = "vmware_test_policy"
$testOraclePolicyName = "oracle_test_policy"
$testClientName = "MEDIA_SERVER"
$testScheduleName = "vmware_test_schedule"
$global:objectGroupId = ""
$global:accessRuleId = ""

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
# Create a vmware policy with default attribute values
#################################################
Function CreateVMwarePolicy()
{
    $uri = $baseUri + $policiesUri

    $policy = @{
        policyName=$testVMwarePolicyName
        policyType="VMware"
    }

    $data = @{
        type="policy"
        id=$testVMwarePolicyName
        attributes=@{policy=$policy}
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 9

    Write-Host "`nSending a POST request to create $testVMwarePolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method POST `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        Write-Host "Unable to create policy $testVMwarePolicyName."
    } else {
        Write-Host "$testVMwarePolicyName created successfully.`n"
    }
    $response = (ConvertFrom-Json -InputObject $response)
}

#################################################
# Create an oracle policy with default attribute values
#################################################
Function CreateOraclePolicy()
{
    $uri = $baseUri + $policiesUri

    $policy = @{
        policyName=$testOraclePolicyName
        policyType="Oracle"
    }

    $data = @{
        type="policy"
        id=$testOraclePolicyName
        attributes=@{policy=$policy}
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 9

    Write-Host "`nSending a POST request to create $testOraclePolicyName..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method POST `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        Write-Host "Unable to create policy $testOraclePolicyName."
    } else {
        Write-Host "$testOraclePolicyName created successfully.`n"
    }

    $response = (ConvertFrom-Json -InputObject $response)
}

#####################
# List all policies
#####################
Function ListPolicies()
{
    $uri = $baseUri + $policiesUri

    Write-Host "`nSending a GET request to list all policies...`n"
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method GET `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 200)
    {
        Write-Host "Unable to list policies.`n"
    } else {
        Write-Host $response
    }

}

#################
# Read a policy
#################
Function ReadPolicy()
{
    $uri = $baseUri + $policiesUri + $testVMwarePolicyName

    Write-Host "`nSending a GET request to read policy $testVMwarePolicyName...`n"
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method GET `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 200)
    {
        throw "Unable to read policy $testVMwarePolicyName.`n"
    }

    Write-Host $response
}

###################
# Delete a vmware policy
###################
Function DeleteVMwarePolicy()
{
    $uri = $baseUri + $policiesUri + $testVMwarePolicyName

    Write-Host "`nSending a DELETE request to delete policy $testVMwarePolicyName..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete policy $testVMwarePolicyName.`n"
    }

    Write-Host "$testVMwarePolicyName deleted successfully.`n"
}

###################
# Delete an oracle policy
###################
Function DeleteOraclePolicy()
{
    $uri = $baseUri + $policiesUri + $testOraclePolicyName

    Write-Host "`nSending a DELETE request to delete policy $testOraclePolicyName..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete policy $testOraclePolicyName.`n"
    }

    Write-Host "$testOraclePolicyName deleted successfully.`n"
}

#################################################
# Create an object group to access VMware policy
#################################################
Function CreateRbacObjectGroupForVMwarePolicy()
{
    $uri = $baseUri + "/rbac/object-groups"

    $criteria = @{
        objectCriterion="policyType eq 40"
        objectType="NBPolicy"
    }

    $data = @{
        type="object-group"
        attributes=@{
            name="VMwarePolicy"
            criteria=@($criteria)
        }
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 9

    Write-Host "`nMaking POST Request to create object group to access only VMware policies..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method POST `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 201)
    {
        throw "Unable to create object group."
    }

    Write-Host "VMwarePolicy object group created successfully.`n"
    $response = (ConvertFrom-Json -InputObject $response)
    $global:objectGroupId = $response.data.id
}

#################################################
# Create a bpnbat user
#################################################
Function CreateBpnbatUser([string]$username, [string]$domain, [string]$password)
{

    $paramValue = "$username $password $domain"
    $command =  'C:/\"Program Files\"/Veritas/NetBackup/bin/bpnbat.exe' + " -AddUser $paramValue"
    Invoke-Expression $command

    Write-Host "Bpnbat user ran successfully.`n"
}

#################################################
# Create access rule for a user with object group
#################################################
Function CreateRbacAccessRules()
{
    $uri = $baseUri + "/rbac/access-rules"

    $data = @{
        type="access-rule"
        attributes=@{
            description="adding VMwarePolicy object group"
        }
        relationships=@{
            userPrincipal=@{
                data=@{
                    type="user-principal"
                    id="rmnus:testuser:vx:testuser"
                }
            }
            objectGroup=@{
                data=@{
                    type="object-group"
                    id="$global:objectGroupId"
                }
            }
            role=@{
                data=@{
                    type="role"
                    id="3"
                }
            }
        }
    }

    $body = @{data=$data} | ConvertTo-Json -Depth 9

    Write-Host "`nMaking POST Request to create access rule..."
    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method POST `
                -Body $body `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 201)
    {
        throw "Unable to create access rule."
    }

    $response = (ConvertFrom-Json -InputObject $response)
    $global:accessRuleId = $response.data.id
    Write-Host "Access rule is created with id [$global:accessRuleId] to access only VMware policies with status code.`n"
}

###################
# Delete an object group
###################
Function DeleteRbacObjectGroupForVMwarePolicy()
{
    $uri = $baseUri + "/rbac/object-groups/" + $global:objectGroupId

    Write-Host "`nMaking DELETE Request to remove the object group $global:objectGroupId..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete object group $global:objectGroupId.`n"
    }

    Write-Host "$global:objectGroupId deleted successfully.`n"
}

###################
# Delete the access rule
###################
Function DeleteRbacAccessRule()
{
    $uri = $baseUri + "/rbac/access-rules/" + $global:accessRuleId

    Write-Host "`nMaking DELETE Request to remove the access rule $global:accessRuleId..."

    $response = Invoke-WebRequest `
                -Uri $uri `
                -Method DELETE `
                -ContentType $contentType `
                -Headers $headers

    if ($response.StatusCode -ne 204)
    {
        throw "Unable to delete access rule $global:accessRuleId.`n"
    }

    Write-Host "$global:accessRuleId access rule deleted successfully.`n"
}

Setup
$loginResponse = Login

#-------------------------------------------------------------- #
#  Create a new rbac user locally using bpnbat to assign object
#  level permissions to the newly created user and perform
#  subsequent operations.
# -------------------------------------------------------------- #
$username = "testuser"
$password = "testpass"
$domainName = "rmnus"
$domainType = "vx"

$headers = @{"Authorization" = $loginResponse.token}
CreateRbacObjectGroupForVMwarePolicy
CreateBpnbatUser $username $domainName $password
CreateRbacAccessRules

CreateVMwarePolicy
CreateOraclePolicy
ListPolicies

$new_rbac_loginResponse = Login
$headers = @{"Authorization" = $new_rbac_loginResponse.token}
ListPolicies
CreateOraclePolicy
DeleteVMwarePolicy
CreateVMwarePolicy

$headers = @{"Authorization" = $loginResponse.token}
DeleteVMwarePolicy
DeleteOraclePolicy
DeleteRbacAccessRule
DeleteRbacObjectGroupForVMwarePolicy
