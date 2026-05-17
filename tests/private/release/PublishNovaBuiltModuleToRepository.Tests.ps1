BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModuleToRepository.ps1')

    function Resolve-NovaSecretValue {param($SecretSources) return $SecretSources.ExplicitValue}
    function Invoke-NovaRepositoryPublishCommand {param($PublishParameters) return $PublishParameters}
}

Describe 'Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable' {
    It 'returns PSGALLERY_API for PSGallery' {
        Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable -Repository 'PSGallery' | Should -Be 'PSGALLERY_API'
    }

    It 'is case-insensitive' {
        Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable -Repository 'psgallery' | Should -Be 'PSGALLERY_API'
    }

    It 'returns $null for other repositories' {
        Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable -Repository 'Custom' | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaRepositoryPublishParameterMap' {
    It 'includes Path, Repository, and ApiKey when given' {
        $params = Get-NovaRepositoryPublishParameterMap -ProjectInfo ([pscustomobject]@{OutputModuleDir='/dist/X'}) -Repository 'PSGallery' -ApiKey 'k' -VerboseRequested:$true
        $params.Path | Should -Be '/dist/X'
        $params.Repository | Should -Be 'PSGallery'
        $params.ApiKey | Should -Be 'k'
        $params.Verbose | Should -BeTrue
    }

    It 'omits ApiKey when not supplied' {
        $params = Get-NovaRepositoryPublishParameterMap -ProjectInfo ([pscustomobject]@{OutputModuleDir='/d'}) -Repository 'PSGallery' -VerboseRequested:$false
        $params.ContainsKey('ApiKey') | Should -BeFalse
        $params.ContainsKey('Verbose') | Should -BeFalse
    }
}

Describe 'Publish-NovaBuiltModuleToRepository' {
    It 'resolves the API key and forwards parameters to the publish command' {
        Mock Invoke-NovaRepositoryPublishCommand {}
        Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir='/d'}) -Repository 'PSGallery' -ApiKey 'k' -Confirm:$false
        Should -Invoke Invoke-NovaRepositoryPublishCommand -Times 1 -ParameterFilter {$PublishParameters.ApiKey -eq 'k' -and $PublishParameters.Repository -eq 'PSGallery'}
    }

    It 'does not call the publish command under -WhatIf' {
        Mock Invoke-NovaRepositoryPublishCommand {}
        Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir='/d'}) -Repository 'PSGallery' -WhatIf
        Should -Invoke Invoke-NovaRepositoryPublishCommand -Times 0
    }
}
