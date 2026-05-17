BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadTarget.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPackageUploadTarget.TestSupport.ps1')
}

Describe 'Resolve-NovaPackageUploadTarget' {
    It 'composes the resolved upload target from its collaborators' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{}}
        $target = Resolve-NovaPackageUploadTarget -ProjectInfo $project -Url 'x' -Repository 'Nexus' -UploadPath 'p'
        $target.Url | Should -Be 'resolved-url'
        $target.UploadPath | Should -Be 'nuget'
        $target.Repository | Should -Be 'Nexus'
        $target.Headers.H | Should -Be '1'
    }
}
