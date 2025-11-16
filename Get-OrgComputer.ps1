#
# Get-OrgComputer.ps1
#
# Retrieve Active Directory computer details
#
param (
    [Parameter(Mandatory = $true)][string]$Args,
    [switch]$GridView = $false
)

# Properties to query
$properties = "Name",
    "CN",
    "Created",
    "Modified",
    "LockedOut",
    "Enabled",
    "logonCount",
    "Description",
    "IPv4Address",
    "MemberOf",
    "SID",
    "DistinguishedName"

# Output properties as needed
$selectProperties = "Name",
    "CN",
    "Created",
    "Modified",
    "Enabled",
    "LockedOut",
    @{label="Logon Count"; expression={ $_.logonCount }},
    "Description",
    "IPv4Address",
    @{label="Groups"; expression={ $_.MemberOf -Replace '^CN=|,.*$' -Join "`n" }},
    "SID",
    "DistinguishedName"

Write-Host "Computer Organization Information:" $Args -NoNewline

$foundComputers = foreach ($orgComputer in $Args) {
    $computers = Get-ADComputer -Filter { Name -like $orgComputer } -Properties $properties
    $computers | Select -Property $selectProperties
}

# Output to grid or console
if ($GridView) {
    $foundComputers | Out-GridView
} else {
    $foundComputers
}
