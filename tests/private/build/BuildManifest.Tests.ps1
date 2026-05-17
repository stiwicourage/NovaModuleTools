BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/BuildManifest.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
    function Get-NovaBuildProjectInfo {param($ProjectInfo); return $ProjectInfo}
    function Get-FunctionNameFromFile {param($filePath); return @('Foo')}
    function Get-AliasInFunctionFromFile {param($filePath); return @()}
    function Assert-ManifestSchema {param($Manifest, $AllowedParameter)}
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

    It 'adds resources/ paths when CopyResourcesToModuleRoot is false' {
        Set-Content -Path (Join-Path $script:ctx.ResourcesDir 'MyFormat.Format.ps1xml') -Value '<x/>'
        Set-Content -Path (Join-Path $script:ctx.ResourcesDir 'MyTypes.Types.ps1xml') -Value '<x/>'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        ($manifest.FormatsToProcess -join ',') | Should -Match 'resources'
        ($manifest.TypesToProcess -join ',') | Should -Match 'resources'
    }

    It 'adds bare filenames when CopyResourcesToModuleRoot is true' {
        $script:ctx.CopyResourcesToModuleRoot = $true
        Set-Content -Path (Join-Path $script:ctx.ResourcesDir 'MyFormat.Format.ps1xml') -Value '<x/>'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.FormatsToProcess | Should -Be 'MyFormat.Format.ps1xml'
    }

    It 'sets Prerelease when version has a prerelease label' {
        $script:ctx.Version = '1.0.0-beta1'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        Build-Manifest -ProjectInfo ([pscustomobject]@{})
        $manifest = Import-PowerShellDataFile -Path $script:ctx.ManifestFilePSD1
        $manifest.PrivateData.PSData.Prerelease | Should -Be 'beta1'
    }

    It 'stops with friendly error when New-ModuleManifest fails' {
        $script:ctx.ManifestFilePSD1 = '/nonexistent/x/y/Out.psd1'
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Assert-ManifestSchema {}
        { Build-Manifest -ProjectInfo ([pscustomobject]@{}) } | Should -Throw -ErrorId 'Nova.Dependency.ModuleManifestCreationFailed'
    }
}
