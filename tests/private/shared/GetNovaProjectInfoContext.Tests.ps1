BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaProjectInfoContext.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
    function Read-ProjectJsonData {param([string]$ProjectJsonPath)}
}

Describe 'Get-NovaProjectInfoContext' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:root -Force
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'throws when project.json is missing in the given folder' {
        {Get-NovaProjectInfoContext -Path $script:root} | Should -Throw
    }

    It 'returns the resolved root, project.json path, and parsed JSON data' {
        Set-Content -LiteralPath (Join-Path $script:root 'project.json') -Value '{"Name": "Demo"}'
        Mock Read-ProjectJsonData {return @{Name = 'Demo'}}

        $context = Get-NovaProjectInfoContext -Path $script:root

        $context.ProjectRoot | Should -Be (Resolve-Path $script:root).Path
        $context.ProjectJson | Should -Match 'project\.json$'
        $context.JsonData.Name | Should -Be 'Demo'
    }
}
