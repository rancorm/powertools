#
# Get-NeverExpires.ps1
#
# Retrieve user accounts with passwords that never expire

$neverExpireUsers = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $true } –Properties "DisplayName","DistinguishedName","pwdLastSet"
$neverExpireUsers | Select-Object -Property "Displayname",@{ Name="Password Last Set";Expression={ [datetime]::FromFileTime($_."pwdLastSet") } },"DistinguishedName"
