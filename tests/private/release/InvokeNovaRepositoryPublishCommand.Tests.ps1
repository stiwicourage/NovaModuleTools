BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaRepositoryPublishCommand.ps1')

    function Publish-PSResource {param($Path, $Repository, $ApiKey) return [pscustomobject]@{Path=$Path; Repository=$Repository; ApiKey=$ApiKey}}
}

Describe 'Invoke-NovaRepositoryPublishCommand' {
    It 'splats the publish parameters into Publish-PSResource' {
        $params = @{Path='/dist'; Repository='PSGallery'; ApiKey='k'}
        $result = Invoke-NovaRepositoryPublishCommand -PublishParameters $params
        $result.Path | Should -Be '/dist'
        $result.Repository | Should -Be 'PSGallery'
        $result.ApiKey | Should -Be 'k'
    }
}
