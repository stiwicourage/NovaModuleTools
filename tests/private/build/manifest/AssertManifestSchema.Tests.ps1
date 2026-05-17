BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/build/manifest/AssertManifestSchema.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Assert-ManifestSchema' {
    It 'returns silently when every key is allowed' {
        {Assert-ManifestSchema -Manifest @{Author = 'me'; Description = 'd'} -AllowedParameter @('Author', 'Description')} |
            Should -Not -Throw
    }

    It 'throws when the manifest contains unknown keys' {
        {Assert-ManifestSchema -Manifest @{Author = 'me'; Bogus = 1} -AllowedParameter @('Author')} |
            Should -Throw
    }
}
