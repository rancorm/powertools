#
# Get-NeverExpires.ps1
#
# Retrieve user accounts with passwords that never expire

$properties = 
    "DisplayName",
    "DistinguishedName",
    "pwdLastSet"

$selectProperties =
    "Displayname",
    @{ Name="Password Last Set"; Expression={ [datetime]::FromFileTime($_."pwdLastSet") } },
    "DistinguishedName"

$neverExpireUsers = Get-ADUser -Filter {
    Enabled -eq $true -and
    PasswordNeverExpires -eq $true
} -Properties $properties

$neverExpireUsers | Select-Object -Property $selectProperties
