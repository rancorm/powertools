#
# Cert-Status.ps1
#
# Output certificates that are expiring in $Days

# Day parameter
Param([Parameter(Mandatory=$false)][Int]$Days=30)

# Retrieve certs
Get-ChildItem -Recurse -ExpiringInDays $Days Cert:
