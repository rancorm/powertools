# Get-DomainDN.ps1
# 
# Outputs the current domain's distinguished name in
# DC=corp,DC=example,DC=com format.

# Method 1: No admin rights or RSAT module needed (.NET directory services)
try {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
    $dn = ($domain.Name -split '\.' | ForEach-Object { "DC=$_" }) -join ','

    Write-Output $dn
} catch {
    # Method 2: Fallback via ADSI rootDSE (works if the machine is domain-joined)
    try {
        $rootDse = [ADSI]"LDAP://RootDSE"
        Write-Output $rootDse.defaultNamingContext.Value
    } catch {
        Write-Error "Unable to determine domain DN. Is this machine domain-joined?" -ErrorAction Stop
    }
}
