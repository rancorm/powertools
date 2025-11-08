#
# Get-ExternalMailboxRules.ps1
#
# Mail Rules That Forward to External Addresses
#
$domains = Get-AcceptedDomain
$mailboxes = Get-Mailbox -ResultSize Unlimited

ForEach ($mailbox in $mailboxes) {
    Write-Host "Checking rules for $($mailbox.displayname) - $($mailbox.PrimarySmtpAddress)" -ForegroundColor Green

    $forwardingRules = $null
    $rules = Get-InboxRule -Mailbox $mailbox.PrimarySmtpAddress
    $forwardingRules = $rules | Where-Object {$_.forwardto -or $_.forwardasattachmentto}
 
    foreach ($rule in $forwardingRules) {
        $recipients = @()
        $recipients = $rule.ForwardTo | Where-Object {$_ -match "SMTP"}
        $recipients += $rule.ForwardAsAttachmentTo | Where-Object {$_ -match "SMTP"}
     
        $externalRecipients = @()
 
        foreach ($recipient in $recipients) {
            $email = ($recipient -split "SMTP:")[1].Trim("]")
            $domain = ($email -split "@")[1]
 
            if ($domains.DomainName -notcontains $domain) {
                $externalRecipients += $email
            }    
        }
 
        if ($externalRecipients) {
            $extRecString = $externalRecipients -join ", "

            Write-Host "$($rule.Name) forwards to $extRecString" -ForegroundColor Yellow
        }
    }
}
