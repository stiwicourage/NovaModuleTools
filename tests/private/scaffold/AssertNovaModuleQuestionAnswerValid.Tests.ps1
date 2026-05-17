BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/AssertNovaModuleQuestionAnswerValid.ps1')

    function Get-AwesomePromptValidationFailure {param($Ask, $Value)}
    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Assert-NovaModuleQuestionAnswerValid' {
    BeforeAll {
        $script:question = [pscustomobject]@{Name = 'ProjectName'}
    }

    It 'returns silently when the validator reports no failure' {
        Mock Get-AwesomePromptValidationFailure {return $null}
        Mock Stop-NovaOperation {throw 'should not be called'}

        {Assert-NovaModuleQuestionAnswerValid -Question $script:question -Value 'NovaThing'} | Should -Not -Throw
        Assert-MockCalled Stop-NovaOperation -Times 0
    }

    It 'stops the operation when the validator reports a failure' {
        Mock Get-AwesomePromptValidationFailure {
            return [pscustomobject]@{
                Message = 'invalid name'
                ErrorId = 'Nova.Validation.ProjectName'
                Category = 'InvalidArgument'
                TargetObject = $Value
            }
        }
        Mock Stop-NovaOperation {throw "$Message ($ErrorId)"}

        {Assert-NovaModuleQuestionAnswerValid -Question $script:question -Value 'bad name'} | Should -Throw '*invalid name*'
        Assert-MockCalled Stop-NovaOperation -Times 1 -ParameterFilter {
            $Message -eq 'invalid name' -and $ErrorId -eq 'Nova.Validation.ProjectName'
        }
    }
}
