<#
.SYNOPSIS
    Retrieves User accounts or User account passwordless status.

.DESCRIPTION
    Check authentication methods, password expiration, and SSPR status.

.PARAMETER <SamName>
    User account to check passwordless authentication methods.
    - Type: string
    - Mandatory: False	

.EXAMPLE
    PS C:\> .\Get-PasswordlessStatus | Where-Object { $_.HasPasswordless -eq $true -and $_.PasswordExpires -eq $true } | Format-Table -AutoSize

.NOTES
    Author: Jonathan Cormier
    Date: January 7, 2026
    Version: 1.0
    Script Purpose: <Brief statement on script's purpose or scope>
    Dependencies:
      Requires: Microsoft Graph PowerShell module
      Required roles: Global Reader, User Administrator, or Authentication Administrator
#>

$global:ExpireInDays = 90

$global:PasswordlessMethods = @(
    "fido2SecurityKey",
    "windowsHelloForBusiness",
    "microsoftAuthenticator",
    "passkey"
)

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All"

$userInput = Read-Host "Enter user UPN (or press Enter for all users)"

# Function to get password expiration date
function Get-PasswordExpiration {
    param([string]$userPrincipalName)

    $user = Get-MgUser -UserId $userPrincipalName
    $passwordProfile = Get-MgUser -UserId $userPrincipalName -Property "PasswordPolicies,LastPasswordChangeDateTime"
    $policy = Get-MgPolicyAuthenticationMethodPolicy -AuthenticationMethodPolicyId "Password"

    if ($passwordProfile.PasswordPolicies -like "*DisablePasswordExpiration*") {
        return $false
    } else {
        $lastSet = $passwordProfile.LastPasswordChangeDateTime
        $expires = $lastSet.AddDays($global:ExpireInDays)

        return $expires
    }
}

# Function to get SSPR registration status
function Get-SsprRegistrationStatus {
    param([string]$userId)

    try {
        $registrationDetail = Get-MgReportAuthenticationMethodUserRegistrationDetail -UserId $userId
        
        return $registrationDetail.IsSsprRegistered
    } catch {
        Write-Warning "Could not retrieve SSPR status for user $userId: $($_.Exception.Message)"
        
        return $null
    }
}

# Specific user
if ($userInput) {
    $user = Get-MgUser -UserId $userInput

    if ($user) {
        Write-Host "\nAuthentication Methods for $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Green

        $authMethods = Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName

        if ($authMethods) {
            $authTable = $authMethods | Select-Object @{Name="Method";Expression={
                switch ($_.AdditionalProperties.methodType) {
                    "fido2SecurityKey" { "FIDO2 Security Key" }
                    "windowsHelloForBusiness" { "Windows Hello for Business" }
                    "microsoftAuthenticator" { "Microsoft Authenticator" }
                    "temporaryAccessPass" { "Temporary Access Pass" }
                    "passkey" { "Passkey" }
                    default { $_.AdditionalProperties.methodType }
                }
            }}, @{Name="Created";Expression={$_.CreatedDateTime}}

            $authTable | Format-Table -AutoSize

            $passwordlessMethods = $authMethods | Where-Object {
                $_.AdditionalProperties.methodType -in $global:PasswordlessMethods
            }

            if ($passwordlessMethods) {
                Write-Host "\nUser has passwordless authentication methods set." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No authentication methods found." -ForegroundColor Red
        }

        # Expiration
        $expiration = Get-PasswordExpiration -userPrincipalName $user.UserPrincipalName
        Write-Host "Password expires: $(if ($expiration -ne $false) { $expiration } else { "No" })" -ForegroundColor Cyan

        # SSPR status
        $ssprStatus = Get-SsprRegistrationStatus -userId $user.Id
        Write-Host "SSPR registration: $(if ($ssprStatus) {"Yes"} else {"No"})" -ForegroundColor Cyan
    } else {
        Write-Host "User not found." -ForegroundColor Red
    }
} else {
    Write-Host "\nChecking all users..."

    $allUsers = Get-MgUser -All
    $results = @()

    foreach ($user in $allUsers) {
        $authMethods = Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName -ErrorAction SilentlyContinue
        $hasPasswordless = $authMethods | Where-Object {
            $_.AdditionalProperties.methodType -in $global:PasswordlessMethods
        }

        $expiration = Get-PasswordExpiration -userPrincipalName $user.UserPrincipalName

        # Get SSPR registration status
        $ssprStatus = Get-SsprRegistrationStatus -userId $user.Id

        $results += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            HasPasswordless = if ($hasPasswordless) { $true } else { $false }
            PasswordExpires = if ($expiration -eq $false) { $false } else { $true }
            PasswordExpiration = $expiration
            IsSsprRegistered = $ssprStatus
            AuthenticationMethods = ($authMethods.AdditionalProperties.methodType -join ", ")
        }
    }

    $results
}
