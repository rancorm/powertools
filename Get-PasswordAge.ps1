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

$Properties =
    "LastLogonTimestamp",
    "PwdLastSet",
    "PasswordNeverExpires",
    "Mail",
    "PasswordExpired"

$SelectProperties =
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
    $TimeSpan = New-TimeSpan -Start ([datetime]::FromFileTime($LastSet)) -End (Get-Date).DateTime
    return $TimeSpan.Days
}

#
if ($CmdUsers.Count) {
    $Users = $CmdUsers | Get-ADUser -Properties $Properties
} else {
    $Users = Get-ADUser -Filter * -Properties $Properties
}

# Check for accounts with passwords last set within $Days
if ($Days -gt 0) {
    $Users = $Users | Where-Object { (New-TimeSpan -Start ([datetime]::FromFileTime($_.pwdLastSet)) -End (Get-Date).DateTime).Days -le $Days }
}

# Include accounts that don't expire?
if ($ExcludeNeverExpires.IsPresent) {
    $Users = $Users | Where-Object { $_.PasswordNeverExpires -eq $false }
}

# Sort results by last password set date
$Users = $Users | Sort PwdLastSet

# Limit results
if ($LastResults) {
    $Users = $Users | Select-Object -First $LastResults
}

# Output
$Users | Select $SelectProperties
