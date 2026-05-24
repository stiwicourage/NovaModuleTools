function Assert-NovaAgenticCopilotShortName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ShortName
    )

    if ( [string]::IsNullOrWhiteSpace($ShortName)) {
        Stop-NovaOperation -Message 'Project short name is required when applying the Agentic Copilot scaffold.' -ErrorId 'Nova.Validation.AgenticCopilotProjectShortNameMissing' -Category InvalidData -TargetObject 'ShortName'
    }

    if ($ShortName -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        Stop-NovaOperation -Message 'Project short name is invalid. Use a short word that starts with a letter and contains only letters or numbers.' -ErrorId 'Nova.Validation.ScaffoldProjectShortNameInvalid' -Category InvalidData -TargetObject $ShortName
    }
}

function Test-NovaAgenticCopilotProjectUsesPester {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    return $ProjectInfo.PSObject.Properties.Name -contains 'Pester'
}

function Get-NovaAgenticCopilotManagedOverwritePathList {
    [CmdletBinding()]
    param()

    return @(
        '.github/agents/'
        '.github/instructions/'
        '.github/prompts/'
        '.github/skills/'
        '.github/copilot-instructions.md'
        '.github/pull_request_template.md'
        'AGENTS.md'
        'CONTRIBUTING.md'
    )
}

function Get-NovaAgenticCopilotAddOnlyPathList {
    [CmdletBinding()]
    param()

    return @(
        'README.md'
        'CHANGELOG.md'
        'RELEASE_NOTE.md'
    )
}

function Get-NovaAgenticCopilotScaffoldPolicy {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        ManagedOverwritePathList = @(Get-NovaAgenticCopilotManagedOverwritePathList)
        AddOnlyPathList = @(Get-NovaAgenticCopilotAddOnlyPathList)
    }
}

function Get-NovaAgenticCopilotScaffoldAnswerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$ShortName
    )

    $enablePester = if (Test-NovaAgenticCopilotProjectUsesPester -ProjectInfo $ProjectInfo) {
        'Yes'
    } else {
        'No'
    }

    return [ordered]@{
        ProjectName = $ProjectInfo.ProjectName
        Description = $ProjectInfo.Description
        ProjectShortName = $ShortName
        EnablePester = $enablePester
    }
}

function Get-NovaAgenticCopilotScaffoldWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ShortName,
        [switch]$OverrideWarningRequested
    )

    $projectInfo = Get-NovaProjectInfo -Path $Path
    Assert-NovaAgenticCopilotShortName -ShortName $ShortName
    $scaffoldPolicy = Get-NovaAgenticCopilotScaffoldPolicy

    return [pscustomobject]@{
        ProjectInfo = $projectInfo
        ProjectRoot = $projectInfo.ProjectRoot
        AnswerSet = Get-NovaAgenticCopilotScaffoldAnswerSet -ProjectInfo $projectInfo -ShortName $ShortName
        OverrideWarningRequested = [bool]$OverrideWarningRequested
        ManagedOverwritePathList = @($scaffoldPolicy.ManagedOverwritePathList)
        AddOnlyPathList = @($scaffoldPolicy.AddOnlyPathList)
        ScaffoldPolicy = $scaffoldPolicy
        Target = $projectInfo.ProjectRoot
        Action = 'Apply Nova Agentic Copilot scaffold'
    }
}
