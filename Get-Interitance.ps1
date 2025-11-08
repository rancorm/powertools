<#
.SYNOPSIS
    Script to quickly find company user account with inheritance.

.DESCRIPTION
    Script will query Active Directory for users with inheritance information.

.PARAMETER NoInherit
    This switch parameter will define what the cmdlet returns.

.EXAMPLE
    C:\PS> Get-Interitance.ps1

.NOTES
    Author: Jonathan Cormier <jonathan@cormier.co>
    Date  : September 26, 2019
#>

param (
    [Parameter(Mandatory = $true)][string]$Pattern,
    [switch]$NoInherit
)

$userProps = @{
    Filter={ Name -like $Pattern -or sAMAccountName -like $Pattern }
    Properties="nTSecurityDescriptor"
}

$areAccessRulesProtected = !$NoInherit

$users = Get-ADUser @userProps | ?{ $_.nTSecurityDescriptor.AreAccessRulesProtected -eq $areAccessRulesProtected }
$users
