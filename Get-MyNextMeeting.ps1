<#
.SYNOPSIS
    Gets the next calendar meeting from Exchange Online.

.DESCRIPTION
    Get-MyNextMeeting retrieves and displays details about the next scheduled meeting 
    from Exchange Online within a specified number of days. Shows meeting subject, 
    organizer, location, start/end times, and duration in a human-readable format.

.PARAMETER Days
    Number of days to look ahead for meetings. Defaults to 7 days.

.EXAMPLE
    .\Get-MyNextMeeting.ps1
    Shows the next meeting within the default 7 day window.

.EXAMPLE
    .\Get-MyNextMeeting.ps1 -Days 14
    Shows the next meeting within the next 14 days.

.NOTES
    File Name     : Get-MyNextMeeting.ps1
    Author        : Jonathan Cormier
    Prerequisite  : ExchangeOnlineManagement Module
    Created       : December 5, 2024
#>
[CmdletBinding()]
param(
  [Parameter(
      HelpMessage = "Number of days to look ahead for meetings"
  )]
  [ValidateRange(1, 365)]
  [int]$Days = 7
)

function Test-ExchangeOnlineConnection {
  [CmdletBinding()]
  param()
  
  try {
    # Check if module is installed
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
	return $false
    }

    # Check if module is imported in current session
    if (!(Get-Module ExchangeOnlineManagement)) {
	return $false
    }

    # Check connection status
    if (!((Get-ConnectionInformation).State -eq 'Connected')) {
	return $false
    }

    return $true
  }
  catch {
    return $false
  }
}

function Get-TimeUntil {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [DateTime]$FutureTime
  )
  
  $timeUntil = $FutureTime - (Get-Date)
  
  if ($timeUntil.Days -gt 0) {
    return "$($timeUntil.Days) days and $($timeUntil.Hours) hours"
  } 
  elseif ($timeUntil.Hours -gt 0) {
    return "$($timeUntil.Hours) hours and $($timeUntil.Minutes) minutes"
  } 
  else {
    return "$($timeUntil.Minutes) minutes"
  }
}

function Get-HumanDuration {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [TimeSpan]$Duration
  )
  
  if ($Duration.Hours -gt 0) {
    if ($Duration.Minutes -gt 0) {
      return "$($Duration.Hours) hour$(if($Duration.Hours -ne 1){'s'}) and $($Duration.Minutes) minute$(if($Duration.Minutes -ne 1){'s'})"
    }
  
    return "$($Duration.Hours) hour$(if($Duration.Hours -ne 1){'s'})"
  } 

  return "$($Duration.Minutes) minute$(if($Duration.Minutes -ne 1){'s'})"
}

if (!(Test-ExchangeOnlineConnection)) {  
  # Handle the disconnected state  
  Write-Error "Exchange Online connection required"
 
  exit
}

$startDate = Get-Date
$endDate = $startDate.AddDays($Days)

try {
  $nextMeeting = Get-CalendarView -StartDate $startDate -EndDate $endDate |
    Select-Object -First 1 -Property @(
      'Subject',
      'Start',
      'End',
      'Duration',
      'Organizer',
      'Location'
    )
  
  # Output next hellscape
  if ($nextMeeting) {
    $beginsText = Get-TimeUntil -FutureTime $nextMeeting.Start
    $durationText = Get-HumanDuration -Duration $nextMeeting.Duration

    Write-Host "`nSubject: $($nextMeeting.Subject)"
    Write-Host "Organizer: $($nextMeeting.Organizer)"
    Write-Host "Location: $($nextMeeting.Location)"
    Write-Host "Begins: $beginsText"
    Write-Host "Duration: $durationText"
    Write-Host "Start: $($nextMeeting.Start.ToString('R'))"
    Write-Host "End: $($nextMeeting.End.ToString('R'))"
  } else {
    Write-Host "`nNo scheduled meetings found" -ForegroundColor Green 
  }
} catch {
  Write-Error "Failed to retrieve calendar: $_"
}
