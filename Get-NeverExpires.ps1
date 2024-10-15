#
# Get-NeverExpires.ps1
#
# Retrieve user accounts with passwords that never expire

$NeverExpireUsers = Get-ADUser -Filter { Enabled -eq $True -and PasswordNeverExpires -eq $True } –Properties "DisplayName","DistinguishedName","pwdLastSet"
$NeverExpireUsers | Select-Object -Property "Displayname",@{ Name="Password Last Set";Expression={ [datetime]::FromFileTime($_."pwdLastSet") } },"DistinguishedName"
