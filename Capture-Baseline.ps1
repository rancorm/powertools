#requires -version 3

<#
.SYNOPSIS
  Generates a baseline of directory ACLs.

.PARAMETER Path
  Root of the tree to baseline. Defaults to the current directory.

.PARAMETER OutputFile
  CSV destination. Defaults to .\dir-acl-baseline-<date>.csv next to the script.
#>

[CmdletBinding()]
param(
  [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$Path = '.',

  [string]$OutputFile = (Join-Path $PSScriptRoot (
      'dir-acl-baseline-{0}.csv' -f (Get-Date -Format yyyyMMdd-HHmm)))
)

$root = (Resolve-Path $Path).ProviderPath

Get-ChildItem $root -Recurse -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    try { $acl = Get-Acl -LiteralPath $_.FullName -ErrorAction Stop } catch {
      Write-Warning "Skipping '$($_.FullName)': $($_.Exception.Message)"; return
    }

    [pscustomobject]@{
      Timestamp       = Get-Date -Format o
      Path            = $_.FullName
      Owner           = $acl.Owner
      Sddl            = $acl.Sddl
      AccessProtected = $acl.AreAccessRulesProtected
      AuditProtected  = $acl.AreAuditRulesProtected
      RuleCount       = @($acl.Access).Count
      ExplicitRules   = @($acl.Access | Where-Object { -not $_.IsInherited }).Count
    }
  } | Export-Csv -LiteralPath $OutputFile -NoTypeInformation

Write-Verbose "Baseline written to $OutputFile"
