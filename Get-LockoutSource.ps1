#
# Get-LockoutSource.ps1
#
# Get account lockout source

param (
    [Parameter(Mandatory = $true)][string]$Username
)

# Find the domain controller PDCe role
$pdce = (Get-AdDomain).PDCEmulator

Write-Host -NoNewline "Retrieving events from" $pdce "for" $Username "..."
Write-Host "..."

# Build the parameters to pass to Get-WinEvent
$gweParams = @{
     ‘Computername’ = $pdce
     ‘LogName’ = ‘Security’
     ‘FilterXPath’ = "*[System[EventID=4740] and EventData[Data[@Name='TargetUserName']='$Username']]"
}

# Query the security event log
$events = Get-WinEvent @gweParams

# Output events
$events | foreach {
    Write-Host $_.TimeCreated $_.Properties[1].Value
}
