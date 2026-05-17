BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadWorkflowTarget.ps1')
}

Describe 'Get-NovaPackageUploadWorkflowTarget' {
    It 'joins upload URLs with comma separators' {
        $list = @([pscustomobject]@{UploadUrl='https://a'}, [pscustomobject]@{UploadUrl='https://b'})
        Get-NovaPackageUploadWorkflowTarget -UploadArtifactList $list | Should -Be 'https://a, https://b'
    }

    It 'returns a single URL when only one artifact is present' {
        Get-NovaPackageUploadWorkflowTarget -UploadArtifactList @([pscustomobject]@{UploadUrl='https://a'}) | Should -Be 'https://a'
    }
}
