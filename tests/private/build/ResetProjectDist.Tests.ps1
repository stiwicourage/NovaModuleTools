BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/ResetProjectDist.ps1')

    function Get-NovaBuildProjectInfo {param([pscustomobject]$ProjectInfo)}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Reset-ProjectDist' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $script:outputDir = Join-Path $script:root 'dist'
        $script:outputModuleDir = Join-Path $script:outputDir 'Module'
        $script:projectData = [pscustomobject]@{
            OutputDir = $script:outputDir
            OutputModuleDir = $script:outputModuleDir
        }
        Mock Get-NovaBuildProjectInfo {return $script:projectData}
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates the output directories when nothing exists yet' {
        Reset-ProjectDist

        Test-Path -LiteralPath $script:outputDir -PathType Container | Should -BeTrue
        Test-Path -LiteralPath $script:outputModuleDir -PathType Container | Should -BeTrue
    }

    It 'removes the existing output directory and recreates a clean tree' {
        $null = New-Item -ItemType Directory -Path $script:outputModuleDir -Force
        Set-Content -LiteralPath (Join-Path $script:outputModuleDir 'stale.txt') -Value 'old'

        Reset-ProjectDist

        Test-Path -LiteralPath (Join-Path $script:outputModuleDir 'stale.txt') | Should -BeFalse
        Test-Path -LiteralPath $script:outputModuleDir -PathType Container | Should -BeTrue
    }

    It 'translates filesystem failures into Stop-NovaOperation' {
        Mock New-Item {throw 'denied'}

        {Reset-ProjectDist} | Should -Throw
    }
}
