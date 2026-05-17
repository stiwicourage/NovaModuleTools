BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/InitializeNovaModuleAgenticCopilotScaffold.ps1')
    . (Join-Path $projectRoot 'src/private/shared/GetNormalizedRelativePath.ps1')

    function Stop-NovaOperation {
        param($Message, $ErrorId, $Category, $TargetObject)
        $exception = [System.IO.InvalidDataException]::new($Message)
        $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $errorRecord
    }
    function Get-NovaModuleAgenticCopilotTemplateRoot {}

    $script:newTextFileFormattingTemplate = {
        param([Parameter(Mandatory)][string]$TemplateRoot)
        $formattingScriptPath = Join-Path $TemplateRoot 'scripts/build/Test-TextFileFormatting.ps1'
        $formattingTestPath = Join-Path $TemplateRoot 'tests/TextFileFormatting.Tests.ps1'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $formattingScriptPath) -Force
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $formattingTestPath) -Force
        Set-Content -LiteralPath $formattingScriptPath -Value "Write-Host 'formatting'" -Encoding utf8 -NoNewline
        Set-Content -LiteralPath $formattingTestPath -Value "Describe 'formatting' {}" -Encoding utf8 -NoNewline
    }
    $script:newReadmeFallbackTokenMap = {
        [ordered]@{
            '{{ProjectName}}' = 'NovaAgentic'
            '{{ShortName}}' = 'NMT'
            '{{ProjectDescription}}' = 'Agentic scaffold.'
            '{{StartHereBody}}' = 'Start here'
        }
    }
}

Describe 'Initialize-NovaModuleAgenticCopilotScaffold' {
    It 'replaces the short name placeholder in generated scaffold files' {
        $templateRoot = Join-Path $TestDrive 'template'
        $projectRoot = Join-Path $TestDrive 'project'
        $templateFilePath = Join-Path $templateRoot '.github/instructions/powershell-coding-standards.instructions.md'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $templateFilePath) -Force
        Set-Content -LiteralPath $templateFilePath -Value 'Use Invoke-{{ShortName}}* for command examples.'
        Mock Get-NovaModuleAgenticCopilotTemplateRoot {$templateRoot}

        Initialize-NovaModuleAgenticCopilotScaffold -Answer @{
            ProjectName = 'NovaAgentic'
            ProjectShortName = 'NMT'
            Description = 'Agentic scaffold'
        } -ProjectRoot $projectRoot

        $content = Get-Content -LiteralPath (Join-Path $projectRoot '.github/instructions/powershell-coding-standards.instructions.md') -Raw
        $content | Should -Match 'Invoke-NMT\*'
        $content | Should -Not -Match '\{\{ShortName\}\}'
        $content | Should -Match "(\r\n|\n)$"
        $content | Should -Not -Match "(\r\n|\n){2,}$"
    }

    It 'handles the text file formatting guardrails for <Scenario>' -ForEach @(
        @{
            Scenario = 'Pester-enabled standard scaffolds'
            TemplateName = 'template-with-formatting'
            ProjectName = 'project-with-formatting'
            EnablePester = 'Yes'
            Example = $false
            ExpectFormattingTest = $true
        }
        @{
            Scenario = 'standard scaffolds without Pester'
            TemplateName = 'template-without-pester'
            ProjectName = 'project-without-pester'
            EnablePester = 'No'
            Example = $false
            ExpectFormattingTest = $false
        }
        @{
            Scenario = 'example scaffolds'
            TemplateName = 'template-example'
            ProjectName = 'project-example'
            EnablePester = $null
            Example = $true
            ExpectFormattingTest = $true
        }
    ) {
        $templateRoot = Join-Path $TestDrive $TemplateName
        $projectRoot = Join-Path $TestDrive $ProjectName
        & $script:newTextFileFormattingTemplate -TemplateRoot $templateRoot
        Mock Get-NovaModuleAgenticCopilotTemplateRoot {$templateRoot}.GetNewClosure()

        $answer = @{
            ProjectName = 'NovaAgentic'
            ProjectShortName = 'NMT'
            Description = 'Agentic scaffold'
        }
        if ($null -ne $EnablePester) {
            $answer.EnablePester = $EnablePester
        }

        Initialize-NovaModuleAgenticCopilotScaffold -Answer $answer -ProjectRoot $projectRoot -Example:$Example

        (Test-Path -LiteralPath (Join-Path $projectRoot 'scripts/build/Test-TextFileFormatting.ps1')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $projectRoot 'tests/TextFileFormatting.Tests.ps1')) | Should -Be $ExpectFormattingTest
    }

    It 'requires a project short name when Agentic Copilot scaffold generation is requested' {
        $thrown = $null
        try {
            Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer @{
                ProjectName = 'NovaAgentic'
                Description = 'Agentic scaffold'
            }
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -Be 'Project short name is required when Agentic Copilot setup is enabled.'
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.AgenticCopilotProjectShortNameMissing'
        $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
        $thrown.TargetObject | Should -Be 'ProjectShortName'
    }

    It 'defaults the project description when the answer description is blank' {
        $tokenMap = Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer @{
            ProjectName = 'NovaAgentic'
            ProjectShortName = 'NMT'
            Description = ' '
        }

        $tokenMap['{{ProjectDescription}}'] | Should -Be 'NovaAgentic is a PowerShell module project scaffolded with NovaModuleTools.'
    }

    It 'falls back to the template README when <Scenario>' -ForEach @(
        @{
            Scenario = 'the example README is missing'
            ProjectName = 'missing-readme'
            ReadmeContent = $null
        }
        @{
            Scenario = 'the example README has no secondary heading'
            ProjectName = 'readme-without-heading'
            ReadmeContent = '# Example project'
        }
    ) {
        $projectRoot = Join-Path $TestDrive $ProjectName
        $null = New-Item -ItemType Directory -Path $projectRoot -Force
        if ($null -ne $ReadmeContent) {
            $readmePath = Join-Path $projectRoot 'README.md'
            Set-Content -LiteralPath $readmePath -Value $ReadmeContent -Encoding utf8 -NoNewline
        }
        $tokenMap = & $script:newReadmeFallbackTokenMap

        $content = Get-NovaModuleAgenticCopilotReadmeContent -TemplateContent 'Name: {{ProjectName}}' -TokenMap $tokenMap -ProjectRoot $projectRoot -Example

        $content | Should -Be 'Name: NovaAgentic'
    }

    It 'merges existing README body into the start-here section when Example mode finds a secondary heading' {
        $projectRoot = Join-Path $TestDrive 'merged-readme-project'
        $null = New-Item -ItemType Directory -Path $projectRoot -Force
        $readmePath = Join-Path $projectRoot 'README.md'
        Set-Content -LiteralPath $readmePath -Value "# Example project`n## Usage`nDo things" -Encoding utf8 -NoNewline
        $tokenMap = & $script:newReadmeFallbackTokenMap

        $content = Get-NovaModuleAgenticCopilotReadmeContent -TemplateContent '{{StartHereBody}}' -TokenMap $tokenMap -ProjectRoot $projectRoot -Example

        $content | Should -Match 'packaged example scaffold'
        $content | Should -Match '## Usage'
    }

    It 'dispatches to the README-aware content builder for README.md and to the generic expander otherwise' {
        $projectRoot = Join-Path $TestDrive 'destination-content'
        $null = New-Item -ItemType Directory -Path $projectRoot -Force
        $scaffoldContext = [ordered]@{
            TokenMap = [ordered]@{'{{X}}' = 'expanded'}
            ProjectRoot = $projectRoot
            Example = $false
        }

        Get-NovaModuleAgenticCopilotDestinationContent -RelativePath 'README.md' -TemplateContent 'X={{X}}' -ScaffoldContext $scaffoldContext | Should -Be 'X=expanded'
        Get-NovaModuleAgenticCopilotDestinationContent -RelativePath 'other.md' -TemplateContent 'Y={{X}}' -ScaffoldContext $scaffoldContext | Should -Be 'Y=expanded'
    }

    It 'normalizes file content trailing whitespace consistently' {
        ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content '' | Should -Be ''
        ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content "`r`n`r`n" | Should -Be "`r`n`r`n"
        ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content "line1`r`nline2" | Should -Be "line1`r`nline2`r`n"
        ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content "line1`nline2" | Should -Be "line1`nline2`n"
        ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content "line1`r`nline2`r`n`r`n" | Should -Be "line1`r`nline2`r`n"
    }
}
