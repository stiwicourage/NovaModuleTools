BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModule.ps1')

    . (Join-Path $PSScriptRoot 'PublishNovaBuiltModule.TestSupport.ps1')
}

Describe 'Publish-NovaBuiltModule' {
    BeforeEach {
        $script:dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:dir | Out-Null
        $script:project = [pscustomobject]@{OutputModuleDir=$script:dir; ProjectName='X'}
    }
    AfterEach {
        Remove-Item -LiteralPath $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'throws when the output dir does not exist' {
        $missing = [pscustomobject]@{OutputModuleDir='/does/not/exist/dist'; ProjectName='X'}
        {Publish-NovaBuiltModule -ProjectInfo $missing} | Should -Throw '*Dist folder is empty*'
    }

    It 'delegates to repository publish when -Repository is set' {
        Mock Publish-NovaBuiltModuleToRepository {}
        Publish-NovaBuiltModule -Repository 'PSGallery' -ProjectInfo $script:project
        Should -Invoke Publish-NovaBuiltModuleToRepository -Times 1
    }

    It 'delegates to directory publish otherwise' {
        Mock Publish-NovaBuiltModuleToDirectory {}
        Publish-NovaBuiltModule -ModuleDirectoryPath '/local' -ProjectInfo $script:project
        Should -Invoke Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {$ModuleDirectoryPath -eq '/local'}
    }

    It 'resolves the local publish path when ModuleDirectoryPath is blank' {
        Mock Publish-NovaBuiltModuleToDirectory {}
        Mock Resolve-NovaLocalPublishPath {return '/local/resolved'}
        Publish-NovaBuiltModule -ProjectInfo $script:project
        Should -Invoke Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {$ModuleDirectoryPath -eq '/local/resolved'}
    }
}
