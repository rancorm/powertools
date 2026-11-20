#
# Search-GPO
#
# Searches on-premise domain GPOs for specific HKLM/HKCU keys
#
param (
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [string]$GPOName = "Default Domain Policy",
    [string]$KeyPattern,
    [switch]$All,
    [switch]$Detail
)

function Recursive($GPOName, $KeyPath) {
    if ($null -eq $KeyPath) {
        Return
    }

    foreach ($item in (Get-GPRegistryValue -Name $GPOName -Key $KeyPath -ErrorAction SilentlyContinue)) {
        if ($item.HasValue) {
            $entry = $GPOName + ":" + $item.KeyPath + "\" + $item.ValueName + " = "

            Write-Host -NoNewLine $entry 
            Write-Host $item.Value
        } else {
            Recursive $GPOName $item.FullKeyPath
        }
    }
}

$nearestDC = (Get-ADDomainController -Discover -NextClosestSite).Name

# Get a list of GPO policies from the domain
$policies = Get-GPO -All -Domain $Domain -Server $nearestDC | sort DisplayName

# Go through each GPO and check for keys and values
foreach ($policy in $policies)  {
    $localMachineKeyPath = "HKLM\Software\"

    Recursive $policy.DisplayName $localMachineKeyPath
}
