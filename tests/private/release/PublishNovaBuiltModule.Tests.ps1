BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModule.ps1')

    function Get-NovaProjectInfo {return [pscustomobject]@{OutputModuleDir='/dist/X'; ProjectName='X'}}
    function Publish-NovaBuiltModuleToRepository {param($ProjectInfo, $Repository, $ApiKey)}
    function Publish-NovaBuiltModuleToDirectory {param($ProjectInfo, $ModuleDirectoryPath)}
    function Resolve-NovaLocalPublishPath {param($ModuleDirectoryPath) return '/local/resolved'}
    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
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
}
