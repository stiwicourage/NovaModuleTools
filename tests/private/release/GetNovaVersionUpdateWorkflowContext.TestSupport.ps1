function Get-NovaCurrentVersionForUpdatePlan {param($ProjectInfo) return [semver]$ProjectInfo.Version}
function Test-GitRepositoryIsAvailable {param($ProjectRoot) $true}
function Stop-NovaOperation {param([string]$Message,[string]$ErrorId,$Category,$TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message),$ErrorId,$Category,$TargetObject)}
function Get-NovaProjectInfo {param($Path) [pscustomobject]@{ProjectJSON='/r/project.json'; Version='1.2.3'}}
function Get-GitCommitMessageForVersionBump {param($ProjectRoot) @('feat: x','fix: y')}
function Get-NovaVersionLabelForBump {param($ProjectRoot,$CommitMessages,[switch]$ContinuousIntegrationRequested) 'Minor'}
function Get-NovaVersionUpdatePlan {param($ProjectInfo,$Label,[switch]$PreviewRelease) [pscustomobject]@{NewVersion=[semver]'1.3.0'}}
