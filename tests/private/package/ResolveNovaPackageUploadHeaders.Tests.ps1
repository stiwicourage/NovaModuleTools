BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadHeaders.ps1')

    function Merge-NovaPackageSettingTable {param($BaseSettings, $OverrideSettings)
        $merged = [ordered]@{}
        foreach ($t in @($BaseSettings, $OverrideSettings)) {
            if ($null -eq $t) {continue}
            foreach ($k in $t.Keys) {$merged[$k] = $t[$k]}
        }
        return $merged
    }
    function Resolve-NovaPackageUploadAuthHeaderEntry {param($AuthSettings, $UploadOption) return $null}
}

Describe 'Resolve-NovaPackageUploadHeaders' {
    It 'returns merged headers when no auth header is resolved' {
        $target = [pscustomobject]@{Headers=@{H='1'}; Auth=$null}
        $option = [pscustomobject]@{Headers=@{X='2'}; Token=''}
        $headers = Resolve-NovaPackageUploadHeaders -UploadTarget $target -UploadOption $option
        $headers['H'] | Should -Be '1'
        $headers['X'] | Should -Be '2'
    }

    It 'adds the auth header when one is resolved' {
        Mock Resolve-NovaPackageUploadAuthHeaderEntry {return [pscustomobject]@{Name='Authorization'; Value='Bearer t'}}
        $target = [pscustomobject]@{Headers=$null; Auth=$null}
        $option = [pscustomobject]@{Headers=$null; Token='t'}
        $headers = Resolve-NovaPackageUploadHeaders -UploadTarget $target -UploadOption $option
        $headers['Authorization'] | Should -Be 'Bearer t'
    }
}
