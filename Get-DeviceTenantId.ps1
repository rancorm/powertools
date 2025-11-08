#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reads the registry to find the Entra ID tenant to which the device is joined.
.DESCRIPTION
    The script walks the "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo" key,
    finds the GUID sub-key that holds the join information, returns TenantId, UserEmail and
    RegistryPath.
#>

$joinInfoPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'

# Make sure the base key exists
if (-not (Test-Path $joinInfoPath)) {
    Write-Warning "JoinInfo key not found – device is not Entra joined."
    return
}

# There is one GUID-named sub-key per Entra join
$guidKey = Get-ChildItem $joinInfoPath -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $guidKey) {
    Write-Warning "No GUID sub-key – no tenant information present."
    return
}

# Read the two useful values
$tenantId = $guidKey.GetValue('TenantId')
$userEmail = $guidKey.GetValue('UserEmail')

[PSCustomObject]@{
    TenantId  = $tenantId
    UserEmail = $userEmail
    RegistryPath = $guidKey.Name
}
