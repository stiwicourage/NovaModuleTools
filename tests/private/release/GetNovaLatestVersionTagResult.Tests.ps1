BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/InvokeNovaGitCommand.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaLatestVersionTagResult.ps1')
    . (Join-Path $projectRoot 'tests/GitTestSupport.ps1')
}

Describe 'Get-NovaLatestVersionTagResult' {
    BeforeEach {
        $script:repositoryPath = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Initialize-TestGitRepository -Path $script:repositoryPath
        New-TestGitCommit -RepositoryPath $script:repositoryPath -Message 'feat: initial' -File @{Name = 'a.txt'; Content = 'a'}
    }

    It 'returns the latest <TagName> version tag' -ForEach @(
        @{TagName = '1.2.3'}
        @{TagName = 'v1.2.3'}
    ) {
        New-TestGitTag -RepositoryPath $script:repositoryPath -TagName $TagName

        $result = Get-NovaLatestVersionTagResult -ProjectRoot $script:repositoryPath

        $result.ExitCode | Should -Be 0
        Get-NovaGitCommandOutputText -Result $result | Should -Be $TagName
    }

    It 'ignores newer tags that are not versions' {
        New-TestGitTag -RepositoryPath $script:repositoryPath -TagName '1.0.0'
        New-TestGitCommit -RepositoryPath $script:repositoryPath -Message 'feat!: drop legacy' -File @{Name = 'b.txt'; Content = 'b'}
        New-TestGitTag -RepositoryPath $script:repositoryPath -TagName 'deploy-marker'

        $result = Get-NovaLatestVersionTagResult -ProjectRoot $script:repositoryPath

        Get-NovaGitCommandOutputText -Result $result | Should -Be '1.0.0'
    }

    It 'fails when only non-version tags exist' {
        New-TestGitTag -RepositoryPath $script:repositoryPath -TagName 'deploy-marker'

        $result = Get-NovaLatestVersionTagResult -ProjectRoot $script:repositoryPath

        $result.ExitCode | Should -Not -Be 0
    }
}
