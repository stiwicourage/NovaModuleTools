BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaProjectInfoContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaProjectInfoContext.TestSupport.ps1')
}

Describe 'Get-NovaProjectInfoContext' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:root -Force
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'throws a clear error when the project path does not exist' {
        {Get-NovaProjectInfoContext -Path (Join-Path $script:root 'missing')} | Should -Throw '*Project path not found:*Run Get-NovaProjectInfo from a Nova project root or pass -Path to an existing project folder.*'
    }

    It 'throws a clear error when the project path points to a file instead of a folder' {
        $filePath = Join-Path $script:root 'project.txt'
        Set-Content -LiteralPath $filePath -Value 'content'

        {Get-NovaProjectInfoContext -Path $filePath} | Should -Throw '*Project path must be a folder:*Pass -Path to the project root that contains project.json.*'
    }

    It 'throws when project.json is missing in the given folder' {
        {Get-NovaProjectInfoContext -Path $script:root} | Should -Throw '*project.json not found in project root:*Run Get-NovaProjectInfo from a folder that contains project.json or pass -Path to that folder.*'
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
