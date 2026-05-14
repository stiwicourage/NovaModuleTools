function Get-NovaModuleSingleWordValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$ErrorId
    )

    $validationPattern = $Pattern

    return @{
        Test = ({
            param($Value)

            return $Value -match $validationPattern
        }).GetNewClosure()
        Message = $Message
        ErrorId = $ErrorId
        Category = [System.Management.Automation.ErrorCategory]::InvalidData
    }
}

function Get-NovaModuleProjectNameValidation {
    return Get-NovaModuleSingleWordValidation -Pattern '^[A-Za-z][A-Za-z0-9_.]*$' -Message 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.' -ErrorId 'Nova.Validation.ScaffoldProjectNameInvalid'
}

function Get-NovaModuleProjectShortNameValidation {
    return Get-NovaModuleSingleWordValidation -Pattern '^[A-Za-z][A-Za-z0-9]*$' -Message 'Project short name is invalid. Use a short word that starts with a letter and contains only letters or numbers.' -ErrorId 'Nova.Validation.ScaffoldProjectShortNameInvalid'
}

function Get-NovaModuleBaseQuestionSet {
    return [ordered]@{
        ProjectName = @{
            Caption = 'Module Name'
            Message = 'Enter Module name of your choice, should be single word with no special characters'
            Prompt = 'Name'
            Default = 'MANDATORY'
            Validation = Get-NovaModuleProjectNameValidation
        }
        Description = @{
            Caption = 'Module Description'
            Message = 'What does your module do? Describe in simple words'
            Prompt = 'Description'
            Default = 'NovaModuleTools Module'
        }
        Version = @{
            Caption = 'Semantic Version'
            Message = 'Starting Version of the module (Default: 0.0.1)'
            Prompt = 'Version'
            Default = '0.0.1'
        }
        Author = @{
            Caption = 'Module Author'
            Message = 'Enter Author or company name'
            Prompt = 'Name'
            Default = 'PS'
        }
        PowerShellHostVersion = @{
            Caption = 'Supported PowerShell Version'
            Message = 'What is minimum supported version of PowerShell for this module (Default: 7.4)'
            Prompt = 'Version'
            Default = '7.4'
        }
        EnableGit = @{
            Caption = 'Git Version Control'
            Message = 'Do you want to enable version controlling using Git'
            Prompt = 'EnableGit'
            Default = 'No'
            Choice = [ordered]@{
                Yes = 'Enable Git'
                No = 'Skip Git initialization'
            }
        }
    }
}

function Get-NovaModulePesterQuestion {
    return @{
        Caption = 'Pester Testing'
        Message = 'Do you want to enable basic Pester Testing'
        Prompt = 'EnablePester'
        Default = 'No'
        Choice = [ordered]@{
            Yes = 'Enable pester to perform testing'
            No = 'Skip pester testing'
        }
    }
}

function Get-NovaModuleAgenticCopilotQuestion {
    return @{
        Caption = 'Agentic Copilot setup'
        Message = 'Do you want Nova to add Agentic Copilot setup files to this project?'
        Prompt = 'EnableAgenticCopilot'
        Default = 'No'
        Choice = [ordered]@{
            Yes = 'Add Agentic Copilot setup'
            No = 'Skip Agentic Copilot setup'
        }
    }
}

function Get-NovaModuleAgenticCopilotProjectShortNameQuestion {
    return @{
        Caption = 'Project short name'
        Message = 'Enter a short project name for generated guidance placeholders such as Invoke-<ShortName>*. For NovaModuleTools the short name is Nova, but it could also have been NMT.'
        Prompt = 'ProjectShortName'
        Default = 'MANDATORY'
        Validation = Get-NovaModuleProjectShortNameValidation
        Condition = {
            param([System.Collections.IDictionary]$Answer)

            return $Answer.Contains('EnableAgenticCopilot') -and $Answer['EnableAgenticCopilot'] -eq 'Yes'
        }
    }
}

function Get-NovaModuleQuestionSet {
    [CmdletBinding()]
    param(
        [switch]$Example
    )

    $questions = Get-NovaModuleBaseQuestionSet
    $questions.EnableAgenticCopilot = Get-NovaModuleAgenticCopilotQuestion
    $questions.ProjectShortName = Get-NovaModuleAgenticCopilotProjectShortNameQuestion

    if (-not $Example) {
        $questions.EnablePester = Get-NovaModulePesterQuestion
    }

    return $questions
}
