
Param(
    [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
    [string[]]$SamAccountName
)

$SamAccountName | Get-ADUser -Properties nTSecurityDescriptor | ?{ $_.nTSecurityDescriptor.AreAccessRulesProtected -eq "True" }