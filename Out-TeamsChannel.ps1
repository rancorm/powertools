<#
.SYNOPSIS
    Script to convert pipeline objects to text and send to Teams channel

.DESCRIPTION
    Script attempt to convert the objects passed through the command line pipe to text
    for sending as an email to a Teams Channel

.PARAMETER Objects
    Objects from the command line pipe

.PARAMETER ChannelEmail
    Teams channel email address to send text

.EXAMPLE
    C:\PS> Get-ADUser jonathanco | Out-TeamsChannel -Email channel@email.ms

.NOTES
    Author: Jonathan Cormier <jonathan@cormier.co>
    Date  : April 1, 2020 
#>

param (
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true)
    ][object[]]$Objects,
    [string]$ChannelEmail
)

function IsValidEmail { 
    param(
        [string]$EmailAddress
    )

    try {
        $null = [mailaddress]$EmailAddress
        return $true
    } catch {
        return $false
    }
}

$channelMail = @{
    "From" = "noreply@example.org"
    "SmtpServer" = "mail.example.org"
    "To" = $channelEmail
    "Port" = 587
}

$channelOutput = ""

foreach ($object in $objects) {
    $channelOutput += ($object | Out-String)
}

$channelOutput
$channelMail
