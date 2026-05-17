BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageOutputDirectory.ps1')
}

Describe 'Get-NovaPackageOutputDirectory' {
    It 'returns the resolved absolute string when configured directly' {
        $abs = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        $project = [pscustomobject]@{ProjectRoot='/proj'; Package=[pscustomobject]@{OutputDirectory=$abs}}
        Get-NovaPackageOutputDirectory -ProjectInfo $project | Should -Be ($abs.Trim())
    }

    It 'returns the configured Path when OutputDirectory is an object' {
        $abs = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        $project = [pscustomobject]@{ProjectRoot='/proj'; Package=[pscustomobject]@{OutputDirectory=[pscustomobject]@{Path=$abs}}}
        Get-NovaPackageOutputDirectory -ProjectInfo $project | Should -Be ($abs.Trim())
    }

    It 'joins relative paths under ProjectRoot' {
        $project = [pscustomobject]@{ProjectRoot='/proj'; Package=[pscustomobject]@{OutputDirectory='out'}}
        Get-NovaPackageOutputDirectory -ProjectInfo $project | Should -Be ([System.IO.Path]::Join('/proj','out'))
    }
}
