BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/UpdateManifestPrivateData.ps1')
    . (Join-Path $projectRoot 'src/private/build/ConvertToPowerShellDataLiteral.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, $Category, $TargetObject)

        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
}

Describe 'Update-ManifestPrivateData' {
    BeforeEach {
        $script:manifestPath = Join-Path $TestDrive 'Demo.psd1'
        New-ModuleManifest -Path $script:manifestPath -RootModule 'Demo.psm1' -ModuleVersion '1.0.0' -Author 'Me' -Tags @('Example') | Out-Null
    }

    It 'merges generated PSData with consumer-defined PrivateData' {
        $privateData = [ordered]@{
            ExampleProduct = [ordered]@{
                Enabled = $true
                ApiVersion = '1'
                RetryCount = 3
                Nested = [ordered]@{
                    Mode = 'Test'
                }
                Values = @('one', 'two')
            }
        }

        Update-ManifestPrivateData -ManifestPath $script:manifestPath -PrivateData $privateData

        $manifest = Import-PowerShellDataFile -LiteralPath $script:manifestPath
        $manifest.PrivateData.PSData.Tags | Should -Be @('Example')
        $manifest.PrivateData.ExampleProduct.Enabled | Should -BeTrue
        $manifest.PrivateData.ExampleProduct.ApiVersion | Should -Be '1'
        $manifest.PrivateData.ExampleProduct.RetryCount | Should -Be 3
        $manifest.PrivateData.ExampleProduct.Nested.Mode | Should -Be 'Test'
        $manifest.PrivateData.ExampleProduct.Values | Should -Be @('one', 'two')

        (Get-Content -LiteralPath $script:manifestPath -Raw) | Should -Match "'PSData' = @\{"
    }

    It 'preserves arbitrary dictionary keys that require quoting' {
        $privateData = [ordered]@{
            'Example Product' = [ordered]@{
                'Feature-Flag' = $true
                "Owner's Choice" = 'ready'
                '123abc' = 3
            }
        }

        Update-ManifestPrivateData -ManifestPath $script:manifestPath -PrivateData $privateData

        $manifest = Import-PowerShellDataFile -LiteralPath $script:manifestPath
        $manifest.PrivateData['Example Product']['Feature-Flag'] | Should -BeTrue
        $manifest.PrivateData['Example Product']["Owner's Choice"] | Should -Be 'ready'
        $manifest.PrivateData['Example Product']['123abc'] | Should -Be 3

        (Get-Content -LiteralPath $script:manifestPath -Raw) | Should -Match "'Example Product' = @\{"
    }

    It 'throws when consumer PrivateData collides with reserved PSData' {
        $privateData = [ordered]@{
            PSData = [ordered]@{
                ExampleProduct = 'bad'
            }
        }

        { Update-ManifestPrivateData -ManifestPath $script:manifestPath -PrivateData $privateData } |
            Should -Throw -ErrorId 'Nova.Configuration.ManifestPrivateDataReservedKey'
    }
}

Describe 'Get-GeneratedManifestPsData' {
    It 'returns null when the manifest has no PrivateData' {
        $manifest = [pscustomobject]@{
            PrivateData = $null
        }

        Get-GeneratedManifestPsData -Manifest $manifest | Should -BeNullOrEmpty
    }

    It 'converts object-based PSData into an ordered dictionary' {
        $manifest = [pscustomobject]@{
            PrivateData = [pscustomobject]@{
                PSData = [pscustomobject]@{
                    Tags = @('Example')
                    ReleaseNotes = 'https://example.test/release'
                }
            }
        }

        $result = Get-GeneratedManifestPsData -Manifest $manifest

        $result | Should -BeOfType ([System.Collections.Specialized.OrderedDictionary])
        $result.Tags | Should -Be @('Example')
        $result.ReleaseNotes | Should -Be 'https://example.test/release'
    }
}

Describe 'Get-ManifestPsDataDictionary' {
    It 'returns null when PSData is null' {
        Get-ManifestPsDataDictionary -PSData $null | Should -BeNullOrEmpty
    }
}

Describe 'Get-ManifestHashtableEntryAst' {
    It 'throws when the generated manifest cannot be parsed' {
        $invalidManifestPath = Join-Path $TestDrive 'Invalid.psd1'
        Set-Content -LiteralPath $invalidManifestPath -Value '@{ PrivateData = ' -NoNewline

        { Get-ManifestHashtableEntryAst -ManifestPath $invalidManifestPath -Name 'PrivateData' } |
            Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestParsingFailed'
    }

    It 'throws when the generated manifest is missing the requested top-level entry' {
        $manifestPath = Join-Path $TestDrive 'MissingEntry.psd1'
        Set-Content -LiteralPath $manifestPath -Value "@{`n    RootModule = 'Demo.psm1'`n}" -NoNewline

        { Get-ManifestHashtableEntryAst -ManifestPath $manifestPath -Name 'PrivateData' } |
            Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestPrivateDataMissing'
    }
}

Describe 'Get-TopLevelManifestHashtableAst' {
    It 'throws when the parsed file does not contain a top-level hashtable' {
        $scriptPath = Join-Path $TestDrive 'NoHashtable.ps1'
        Set-Content -LiteralPath $scriptPath -Value "'plain text'" -NoNewline
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)

        { Get-TopLevelManifestHashtableAst -Ast $ast } |
            Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestParsingFailed'
    }
}
