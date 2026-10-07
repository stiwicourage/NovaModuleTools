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
