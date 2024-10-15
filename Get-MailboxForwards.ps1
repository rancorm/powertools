<#
.SYNOPSIS
    Script to output any type of forwarding on an Exchange mailbox.

.DESCRIPTION
    This script will query Exchange mailbox for forwarding settings and rules.

.PARAMETER Mailbox
    This parameter defined the maibox to check for forwarding.

.EXAMPLE
    C:\PS> Get-InboxForwarding -Mailbox jctest
    
    This command will output any forwarding on the mailbox.
#>

param (
    [Parameter(Mandatory = $true)][string]$Mailbox
)

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

$Mbx = Get-Mailbox $Mailbox

$ForwardingRules = $null
$Rules = Get-InboxRule -Mailbox $Mbx.Name

# Retrieve inbox rules that forward
$ForwardingRules = $Rules | Where-Object { $_.ForwardTo -or $_.ForwardAsAttachmentTo }
$NumberOfForwardingRules = $ForwardingRules | Measure-Object

if ($NumberOfForwardingRules.Count -gt 0) {
    foreach ($Rule in $ForwardingRules) {
        $RuleHash = $null

        $RuleHash = [Ordered]@{
            DisplayName                = $Mbx.DisplayName
            PrimarySmtpAddress         = $Mbx.PrimarySmtpAddress
            ForwardingAddress          = $Mbx.ForwardingAddress
            ForwardingSmtpAddress      = $Mbx.ForwardingSmtpAddress
            DeliverToMailboxAndForward = $Mbx.DeliverToMailboxAndForward
            RuleId                     = $Rule.Identity
            RuleName                   = $Rule.Name
            RuleEnabled                = $Rule.Enabled
            RuleDescription            = $Rule.Description
        }
        
        $RuleObject = New-Object PSObject -Property $RuleHash
        $RuleObject
    }
} else {
    # No rules just output ForwardingAddress, ForwardingSmtpAddress, and DeliverToMailboxAndForward only.
    $Mbx | Select DisplayName,PrimarySmtpAddress,ForwardingAddress,ForwardingSmtpAddress,DeliverToMailboxAndForward
}
