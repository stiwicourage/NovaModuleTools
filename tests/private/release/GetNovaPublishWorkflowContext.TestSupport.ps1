function Resolve-NovaPublishInvocation {param($ProjectInfo, $Repository, $ModuleDirectoryPath, $ApiKey)
    return [pscustomobject]@{
        IsLocal = [string]::IsNullOrEmpty($Repository)
        Target = if ($Repository) {$Repository} else {$ModuleDirectoryPath}
        Parameters = @{ProjectInfo = $ProjectInfo}
    }
}
function Get-NovaLocalPublishActivation {param($PublishInvocation) return 'activation'}
function Get-NovaPublishWorkflowOperation {param([bool]$IsLocal, [switch]$Release, [switch]$SkipTestsRequested) return 'operation'}
