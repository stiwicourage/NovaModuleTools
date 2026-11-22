function Install-PSResource {param([string]$Name, [string]$Version, [string]$Repository, [string]$Scope)}
function Write-Message {param([string]$Text, [string]$color)}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message), $ErrorId, $Category, $TargetObject)}

function New-NovaTestShouldProcessCmdlet {
    param([bool]$Approve)

    $cmdlet = [pscustomobject]@{Approve = $Approve; Target = $null; Action = $null}
    $cmdlet | Add-Member -MemberType ScriptMethod -Name ShouldProcess -Value {
        param([string]$Target, [string]$Action)
        $this.Target = $Target
        $this.Action = $Action
        return $this.Approve
    }
    return $cmdlet
}
