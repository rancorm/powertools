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

$mbx = Get-Mailbox $mailbox

$forwardingRules = $null
$rules = Get-InboxRule -Mailbox $mbx.Name

# Retrieve inbox rules that forward
$forwardingRules = $rules | Where-Object { $_.ForwardTo -or $_.ForwardAsAttachmentTo }
$numberOfForwardingRules = $forwardingRules | Measure-Object

if ($numberOfForwardingRules.Count -gt 0) {
    foreach ($rule in $forwardingRules) {
        $ruleHash = $null

        $ruleHash = [Ordered]@{
            DisplayName                = $mbx.DisplayName
            PrimarySmtpAddress         = $mbx.PrimarySmtpAddress
            ForwardingAddress          = $mbx.ForwardingAddress
            ForwardingSmtpAddress      = $mbx.ForwardingSmtpAddress
            DeliverToMailboxAndForward = $mbx.DeliverToMailboxAndForward
            RuleId                     = $rule.Identity
            RuleName                   = $rule.Name
            RuleEnabled                = $rule.Enabled
            RuleDescription            = $rule.Description
        }
        
        $ruleObject = New-Object PSObject -Property $ruleHash
        $ruleObject
    }
} else {
    # No rules just output ForwardingAddress, ForwardingSmtpAddress, and DeliverToMailboxAndForward only.
    $mbx | Select DisplayName,PrimarySmtpAddress,ForwardingAddress,ForwardingSmtpAddress,DeliverToMailboxAndForward
}
