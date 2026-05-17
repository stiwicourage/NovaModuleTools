BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageUploadDynamicParameterDictionary.ps1')
}

Describe 'New-NovaPackageUploadDynamicParameterDictionary' {
    It 'exposes the expected dynamic parameter names' {
        $dictionary = New-NovaPackageUploadDynamicParameterDictionary
        $dictionary.Keys | Should -Contain 'UploadPath'
        $dictionary.Keys | Should -Contain 'Headers'
        $dictionary.Keys | Should -Contain 'Token'
        $dictionary.Keys | Should -Contain 'TokenEnvironmentVariable'
        $dictionary.Keys | Should -Contain 'AuthenticationScheme'
    }

    It 'declares Headers as a hashtable' {
        $dictionary = New-NovaPackageUploadDynamicParameterDictionary
        $dictionary['Headers'].ParameterType | Should -Be ([hashtable])
    }
}
