BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageAuthorList.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaPackageAuthorList' {
    It 'returns an empty array when value is null' {
        @(Get-NovaPackageAuthorList -AuthorValue $null).Count | Should -Be 0
    }

    It 'returns the trimmed string in a single-element array' {
        Get-NovaPackageAuthorList -AuthorValue '  alice  ' | Should -Be 'alice'
    }

    It 'returns empty when string is whitespace' {
        @(Get-NovaPackageAuthorList -AuthorValue '   ').Count | Should -Be 0
    }

    It 'deduplicates an array of authors' {
        $result = Get-NovaPackageAuthorList -AuthorValue @('alice','bob','alice')
        $result.Count | Should -Be 2
    }

    It 'throws when value is not a string or enumerable' {
        {Get-NovaPackageAuthorList -AuthorValue ([pscustomobject]@{})} | Should -Throw '*must be a string*'
    }
}
