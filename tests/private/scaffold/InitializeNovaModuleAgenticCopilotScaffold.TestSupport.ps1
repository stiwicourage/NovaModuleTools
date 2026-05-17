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
