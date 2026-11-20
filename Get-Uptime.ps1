#requires -version 2

<#
.SYNOPSIS
  Outputs the last bootup time and uptime for one or more computers.

.DESCRIPTION
  Outputs the last bootup time and uptime for one or more computers.

.PARAMETER ComputerName
  One or more computer names. The default is the current computer. Wildcards are not supported.

.PARAMETER Credential
  Specifies credentials that have permission to connect to the remote computer. This parameter is ignored for the current computer.

.OUTPUTS
  PSObjects containing the computer name, the last bootup time, and the uptime.
#>

[CmdletBinding()]
param(
  [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    $ComputerName,
  [System.Management.Automation.PSCredential]
    $Credential
)

begin {
  function Out-Object {
    param([System.Collections.Hashtable[]] $HashData)
    
    $order = @()
    $result = @{}
    $hashData | ForEach-Object {
      $order += ($_.Keys -as [Array])[0]
      $result += $_
    }
    
    New-Object PSObject -Property $result | Select-Object $order
  }

  function Format-TimeSpan {
    process {
      "{0:00} d {1:00} h {2:00} m {3:00} s" -f $_.Days,$_.Hours,$_.Minutes,$_.Seconds
    }
  }

  function Get-Uptime {
    param(
      $ComputerName,
      [System.Management.Automation.PSCredential] $Credential
    )

    # In case pipeline input contains ComputerName property
    if ($ComputerName.ComputerName) {
      $name = $ComputerName.ComputerName
    }

    if ((-not $name) -or ($name -eq ".")) {
      $name = [Net.Dns]::GetHostName()
    }

    $params = @{
      "Class" = "Win32_OperatingSystem"
      "ComputerName" = $name
      "Namespace" = "root\CIMV2"
    }

    if ($Credential) {
      # Ignore -Credential for current computer
      if ($name -ne [Net.Dns]::GetHostName()) {
        $params.Add("Credential", $Credential)
      }
    }

    try {
      $wmiOS = Get-WmiObject @params -ErrorAction Stop
    } catch {
      Write-Error -Exception (New-Object $_.Exception.GetType().FullName `
        ("Cannot connect to the computer '$computerName' due to the following error: '$($_.Exception.Message)'",
        $_.Exception))
      
      return
    }
    
    $lastBootTime = [Management.ManagementDateTimeConverter]::ToDateTime($wmiOS.LastBootUpTime)
    
    Out-Object `
      @{"ComputerName" = $name},
      @{"LastBootTime" = $lastBootTime},
      @{"Uptime"       = (Get-Date) - $lastBootTime | Format-TimeSpan}
  }
}

process {
  if ($ComputerName) {
    foreach ($name in $ComputerName) {
      Get-Uptime $name $Credential
    }
  }
  else {
    Get-Uptime "."
  }
}
