############################################################################################################################################
# Script that allows to get all the members of all the Guest Users in an Office 365 tenant by means of Azure AD PowerShell cmdlets
# Required Parameters:
#  -> CSVFilenName: Name of the file to be generated
############################################################################################################################################
$sCSVFileName = "O365-GuestsUsers.csv"

$host.Runspace.ThreadOptions = "ReuseThread"

# Definition of the function that get all the Guest Users in an Office 365 tenant through Azure AD PowerShell cmdlets and export the results to a CSV file
function Get-O365GuestsUsersThroughAzureAD {   
    param($CSVFileName)

    Try {   
        [array]$guestsUsers = $null
        
        $tenantGuestsUsers = Get-AzADUser | Where-Object { $_.UserPrincipalName -like "*#EXT#*" }

        foreach ($guestUser in $tenantGuestsUsers) { 
            $guestsUsers = New-Object PSObject
            $guestsUsers | Add-Member NoteProperty -Name "Guest User DisplayName" -Value $guestUser.DisplayName
            $guestsUsers | Add-Member NoteProperty -Name "User Principal Name" -Value $guestUser.UserPrincipalName
            $guestsUsers | Add-Member NoteProperty -Name "Mail Address" -Value $guestUser.Mail

            $allGuestsUsers += $guestsUsers
        }

        $allGuestsUsers | Export-Csv $CSVFileName
    } catch [System.Exception] {
        Write-Host -ForegroundColor Red $_.Exception.ToString()   
    } 
}

# Connection to Office 365
$cred = Get-Credential

# Creating an EXO PowerShell session
Connect-AzAccount -Credential $cred -Confirm:$true

# Getting Tenant Guests Users
Get-O365GuestsUsersThroughAzureAD -CSVFileName $sCSVFileName
