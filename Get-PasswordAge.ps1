<#
.SYNOPSIS
    Script to query Active Directory for User password age.

.DESCRIPTION
    This script will query Active Directory for user password age information. Optional arguments
    Days, ResultSize, and IncludeNeverExpires help limit the output.

.PARAMETER Days
    This parameter will define the number of days.

.PARAMETER ResultSize
    This parameter defines the result size.

.PARAMETER ExcludeNeverExpires
    This parameter defines whether or not to include users with passwords that don't expire.

.EXAMPLE
    C:\PS> Get-PasswordAge.ps1 -Days 7
    
    This command will get list of users with passwords set seven (7) days or earlier.
#>
param (
    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$true)
    ][string[]]$CmdUsers,
    [int]$Days = 7,
    [int]$LastResults = 0,
    [switch]$ExcludeNeverExpires,
    [switch]$ExcludeDisabledUsers = $false
)

$properties =
    "LastLogonTimestamp",
    "PwdLastSet",
    "PasswordNeverExpires",
    "Mail",
    "PasswordExpired"

$selectProperties =
    "Name",
    @{Name="Last Logon"; Expression={ ([datetime]::FromFileTime($_.LastLogonTimeStamp)) }},
    "Mail",
    @{Name="Account Name"; Expression={ $_.SAMAccountName }},
    @{Name="Last Set"; Expression={ ([datetime]::FromFileTime($_.pwdLastSet)) }},
    @{Name="Age"; Expression={ CalcPwdAge($_.pwdLastSet) }},
    @{Name="Password Expired"; Expression="PasswordExpired"},
    @{Name="Never Expires"; Expression={ $_.PasswordNeverExpires }},
    "Enabled"

function CalcPwdAge($LastSet) {
    $timeSpan = New-TimeSpan -Start ([datetime]::FromFileTime($LastSet)) -End (Get-Date).DateTime
    return $timeSpan.Days
}

#
if ($cmdUsers.Count) {
    $users = $CmdUsers | Get-ADUser -Properties $properties
} else {
    $users = Get-ADUser -Filter * -Properties $properties
}

# Check for accounts with passwords last set within $days
if ($days -gt 0) {
    $users = $users | Where-Object { (New-TimeSpan -Start ([datetime]::FromFileTime($_.pwdLastSet)) -End (Get-Date).DateTime).Days -le $days }
}

# Include accounts that don't expire?
if ($excludeNeverExpires.IsPresent) {
    $users = $users | Where-Object { $_.PasswordNeverExpires -eq $false }
}

# Sort results by last password set date
$users = $users | Sort PwdLastSet

# Limit results
if ($lastResults) {
    $users = $users | Select-Object -First $lastResults
}

# Output
$users | Select $selectProperties
