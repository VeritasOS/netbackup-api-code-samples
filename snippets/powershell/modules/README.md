To use modules we include this in all of our scripts:
This will search for all the modules and make them available.   We update the drive letter depending on use case.

$PS_Modules = Get-ChildItem c:\ -ErrorAction SilentlyContinue -filter "GTSESS*-modules" -Recurse
foreach ($module in $PS_Modules)
{
$path = $module.FullName
get-childitem $path\*.ps1 -Recurse | % {. $_.FullName}
}
