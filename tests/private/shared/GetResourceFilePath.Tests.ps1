BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetResourceFilePath.ps1')

    . (Join-Path $PSScriptRoot 'GetResourceFilePath.TestSupport.ps1')
}

Describe 'Get-ResourceFilePath' {
    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $script:resourcesDir = Join-Path $script:tempRoot 'resources'
        $null = New-Item -ItemType Directory -Path $script:resourcesDir -Force
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns the project resource path when found' {
        Set-Content -LiteralPath (Join-Path $script:resourcesDir 'Schema.json') -Value '{}'
        Mock Get-NovaProjectInfo {return [pscustomobject]@{ResourcesDir = $script:resourcesDir}}

        $result = Get-ResourceFilePath -FileName 'Schema.json'

        $result | Should -Be (Join-Path $script:resourcesDir 'Schema.json')
    }

    It 'throws when no candidate path exists' {
        Mock Get-NovaProjectInfo {return [pscustomobject]@{ResourcesDir = $script:resourcesDir}}

        {Get-ResourceFilePath -FileName 'Missing.json'} | Should -Throw
    }

    It 'writes a verbose fallback message when project resource discovery throws' {
        Mock Get-NovaProjectInfo { throw 'no project context' }
        Mock Test-Path { return $true }

        $output = Get-ResourceFilePath -FileName 'Schema.json' -Verbose 4>&1
        ($output | Out-String) | Should -Match 'Project resource discovery unavailable'
        ($output | Out-String) | Should -Match 'Schema.json'
    }
}
