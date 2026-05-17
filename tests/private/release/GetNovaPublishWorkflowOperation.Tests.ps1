BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishWorkflowOperation.ps1')
}

Describe 'Get-NovaPublishWorkflowOperation' {
    It 'describes a release run with tests' {
        Get-NovaPublishWorkflowOperation -IsLocal:$false -Release | Should -Match 'release workflow \(build, test, and publish\) to repository'
    }

    It 'describes a release run skipping tests' {
        Get-NovaPublishWorkflowOperation -IsLocal:$true -Release -SkipTestsRequested | Should -Match 'release workflow \(build and publish\) to local directory'
    }

    It 'describes a non-release publish to repository' {
        Get-NovaPublishWorkflowOperation -IsLocal:$false | Should -Match 'Build, test, and publish Nova module to repository'
    }

    It 'mentions skipping tests for non-release publish' {
        Get-NovaPublishWorkflowOperation -IsLocal:$true -SkipTestsRequested | Should -Match 'skip tests, and publish'
    }
}
