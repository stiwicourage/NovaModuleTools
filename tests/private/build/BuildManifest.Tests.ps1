BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/BuildManifest.ps1')
    . (Join-Path $projectRoot 'src/private/build/UpdateManifestPrivateData.ps1')
    . (Join-Path $projectRoot 'src/private/build/ConvertToPowerShellDataLiteral.ps1')
    . (Join-Path $projectRoot 'src/private/build/manifest/GetFunctionNameFromFile.ps1')
    . (Join-Path $projectRoot 'src/private/build/manifest/GetAliasNameFromFunction.ps1')
    . (Join-Path $projectRoot 'src/private/build/manifest/AssertManifestSchema.ps1')

    . (Join-Path $PSScriptRoot 'BuildManifest.TestSupport.ps1')
}

Describe 'Build-Manifest' {
    BeforeEach {
        $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $pub = Join-Path $script:tmp 'src/public'
        $res = Join-Path $script:tmp 'resources'
        $dist = Join-Path $script:tmp 'dist'
        New-Item -ItemType Directory -Path $pub, $res, $dist -Force | Out-Null
        Set-Content -Path (Join-Path $pub 'Foo.ps1') -Value 'function Foo {}'
        $script:ctx = [pscustomobject]@{
            PublicDir = $pub
            ResourcesDir = $res
            CopyResourcesToModuleRoot = $false
            Manifest = @{Author='Me'}
            Version = '1.0.0'
            Description = 'A module'
            ManifestFilePSD1 = Join-Path $dist 'Out.psd1'
            ProjectName = 'Out'
        }
    }
    AfterEach { Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }

    It 'creates a manifest with the configured fields' {
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Mock Get-FunctionNameFromFile { @('Foo') }
        Mock Get-AliasInFunctionFromFile { @() }
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        Test-Path $script:ctx.ManifestFilePSD1 | Should -BeTrue
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.ModuleVersion | Should -Be '1.0.0'
        $manifest.RootModule | Should -Be 'Out.psm1'
        $manifest.Description | Should -Be 'A module'
    }

    It 'records resource manifest entries for CopyResourcesToModuleRoot=<CopyResourcesToModuleRoot>' -ForEach @(
        @{
            CopyResourcesToModuleRoot = $false
            ExpectedFormat = 'resources/MyFormat.Format.ps1xml'
            ExpectedType = 'resources/MyTypes.Types.ps1xml'
        }
        @{
            CopyResourcesToModuleRoot = $true
            ExpectedFormat = 'MyFormat.Format.ps1xml'
            ExpectedType = 'MyTypes.Types.ps1xml'
        }
    ) {
        $script:ctx.CopyResourcesToModuleRoot = $CopyResourcesToModuleRoot
        Set-Content -Path (Join-Path $script:ctx.ResourcesDir 'MyFormat.Format.ps1xml') -Value '<x/>'
        Set-Content -Path (Join-Path $script:ctx.ResourcesDir 'MyTypes.Types.ps1xml') -Value '<x/>'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.FormatsToProcess | Should -Be $ExpectedFormat
        $manifest.TypesToProcess | Should -Be $ExpectedType
    }

    It 'sets Prerelease when version has a prerelease label' {
        $script:ctx.Version = '1.0.0-beta1'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.PrivateData.PSData.Prerelease | Should -Be 'beta1'
    }

    It 'merges generated PSData and configured Manifest.PrivateData into the generated manifest' {
        $script:ctx.Manifest = @{
            Author = 'Me'
            Tags = @('Example')
            PrivateData = [ordered]@{
                'Example Product' = [ordered]@{
                    'Feature-Flag' = $true
                    ApiVersion = '1'
                    RetryCount = 3
                    'Nested Data' = [ordered]@{
                        Mode = 'Test'
                    }
                    Values = @('one', 'two')
                }
            }
        }
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}

        Build-Manifest -ProjectInfo ([pscustomobject]@{})

        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.PrivateData.PSData.Tags | Should -Be @('Example')
        $manifest.PrivateData['Example Product']['Feature-Flag'] | Should -BeTrue
        $manifest.PrivateData['Example Product'].ApiVersion | Should -Be '1'
        $manifest.PrivateData['Example Product'].RetryCount | Should -Be 3
        $manifest.PrivateData['Example Product']['Nested Data'].Mode | Should -Be 'Test'
        $manifest.PrivateData['Example Product'].Values | Should -Be @('one', 'two')
    }

    It 'stops with friendly error when rewritten PrivateData leaves an invalid manifest' {
        $script:ctx.Manifest = @{
            Author = 'Me'
            PrivateData = [ordered]@{
                ExampleProduct = [ordered]@{
                    Enabled = $true
                }
            }
        }
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Mock Update-ManifestPrivateData {}
        Mock Import-PowerShellDataFile -ParameterFilter {$LiteralPath -eq $script:ctx.ManifestFilePSD1} {
            throw [System.Exception]::new('invalid data file')
        }

        { Build-Manifest -ProjectInfo ([pscustomobject]@{}) } |
            Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestPrivateDataValidationFailed'
    }

    It 'throws when configured Manifest.PrivateData collides with PSData' {
        $script:ctx.Manifest = @{
            Author = 'Me'
            PrivateData = @{
                PSData = @{
                    ExampleProduct = 'bad'
                }
            }
        }
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}

        { Build-Manifest -ProjectInfo ([pscustomobject]@{}) } |
            Should -Throw -ErrorId 'Nova.Configuration.ManifestPrivateDataReservedKey'
    }

    It 'stops with friendly error when New-ModuleManifest fails' {
        $script:ctx.ManifestFilePSD1 = '/nonexistent/x/y/Out.psd1'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        { Build-Manifest -ProjectInfo ([pscustomobject]@{}) } | Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestCreationFailed'
    }
}
