<#
.SYNOPSIS
    Queries Active Directory for users that Direct Report to given user

.DESCRIPTION
    This script will query Active Directory for users that direct report to a given user
    and output them to the console.

.PARAMETER Username
    This parameter will define the username which to collect direct reports.

.EXAMPLE
    C:\PS> Get-DirectReports.ps1 jonathanco

.NOTES
    Author: Jonathan Cormier <jonathan@cormier.co>
#>
param (
    [Parameter(Mandatory=$true)][string]$Username
)

$manager = Get-ADUser -Properties Mail,DirectReports $Username
$directReports = $manager | Select-Object -ExpandProperty DirectReports
$directReportUsers = @()

# $DirectReports | Select @{label="Name"; expression={ $_ -Replace '^CN=|,.*$' }}

# Add direct report email addresses
foreach ($directReportDN in $directReports) {
    $directReportUser = Get-ADUser $directReportDN
    $directReportUsers += $directReportUser
}

$directReportUsers
