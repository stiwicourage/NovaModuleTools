function Get-NovaModuleQuestionSet {
    [CmdletBinding()]
    param()

    return [ordered]@{
        ProjectName = @{
            Caption = 'Module Name'
            Message = 'Enter Module name of your choice, should be single word with no special characters'
            Prompt = 'Name'
            Default = 'MANDATORY'
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
        EnablePester = @{
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
}


