BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/build/manifest/AssertManifestSchema.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, $Category, $TargetObject)

        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
}

Describe 'Assert-ManifestSchema' {
    It 'returns silently when every key is allowed' {
        {Assert-ManifestSchema -Manifest @{Author = 'me'; Description = 'd'} -AllowedParameter @('Author', 'Description')} |
            Should -Not -Throw
    }

    It 'throws a sorted error when the manifest contains unknown keys' {
        $thrown = $null

        try {
            Assert-ManifestSchema -Manifest @{
                Zebra = 1
                Author = 'me'
                Alpha = 2
            } -AllowedParameter @('Author')
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.ManifestUnknownParameter'
        $thrown.Exception.Message | Should -Be 'Unknown parameter(s) in Manifest: Alpha, Zebra'
        @($thrown.TargetObject) | Should -Be @('Alpha', 'Zebra')
    }
}
