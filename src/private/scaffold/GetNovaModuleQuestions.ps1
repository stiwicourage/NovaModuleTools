function Get-NovaModuleProjectNameValidation {
    return @{
        Test = {
            param($Value)

            return $Value -match '^[A-Za-z][A-Za-z0-9_.]*$'
        }
        Message = 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.'
        ErrorId = 'Nova.Validation.ScaffoldProjectNameInvalid'
        Category = [System.Management.Automation.ErrorCategory]::InvalidData
    }
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

function Get-NovaModuleQuestionSet {
    [CmdletBinding()]
    param(
        [switch]$Example
    )

    $questions = Get-NovaModuleBaseQuestionSet

    if (-not $Example) {
        $questions.EnablePester = Get-NovaModulePesterQuestion
    }

    return $questions
}
