BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/ResolveNovaPublishInvocation.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPublishInvocation.TestSupport.ps1')
}

Describe 'Resolve-NovaPublishInvocation' {
    It 'builds a repository invocation when -Repository is given' {
        $invocation = Resolve-NovaPublishInvocation -ProjectInfo ([pscustomobject]@{ProjectName='X'}) -Repository 'PSGallery' -ApiKey 'k'
        $invocation.IsLocal | Should -BeFalse
        $invocation.Target | Should -Be 'PSGallery'
        $invocation.Parameters.Repository | Should -Be 'PSGallery'
        $invocation.Parameters.ApiKey | Should -Be 'k'
    }

    It 'builds a local invocation when no repository is given' {
        $invocation = Resolve-NovaPublishInvocation -ProjectInfo ([pscustomobject]@{ProjectName='X'})
        $invocation.IsLocal | Should -BeTrue
        $invocation.Target | Should -Be '/local-resolved'
        $invocation.Parameters.ModuleDirectoryPath | Should -Be '/local-resolved'
    }
}
