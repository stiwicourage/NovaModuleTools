BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleUpdateLookupScript.ps1')

    function Get-ResourceFilePath {param([string]$FileName)}
}

Describe 'Get-NovaModuleUpdateLookupScript' {
    It 'reads the bundled update lookup script as a raw string' {
        $tempFile = New-TemporaryFile
        try {
            Set-Content -LiteralPath $tempFile.FullName -Value "param(`$name)`r`nreturn `$name" -NoNewline
            Mock Get-ResourceFilePath {return $tempFile.FullName}

            $script = Get-NovaModuleUpdateLookupScript

            $script | Should -Match 'param\(\$name\)'
            Assert-MockCalled Get-ResourceFilePath -Times 1 -ParameterFilter {
                $FileName -eq 'update/ModuleUpdateLookup.ps1.txt'
            }
        } finally {
            Remove-Item -LiteralPath $tempFile.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}
