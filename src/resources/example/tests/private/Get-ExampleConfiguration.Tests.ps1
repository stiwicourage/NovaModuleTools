BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    function Stop-NovaOperation {
        [CmdletBinding(SupportsShouldProcess)]
        param($Message, $ErrorId, $Category, $TargetObject)

        $null = $PSCmdlet.ShouldProcess([string]$TargetObject, 'Stop-NovaOperation')
        throw "$Message [$ErrorId | $Category | $TargetObject]"
    }

    . (Join-Path $projectRoot 'src/private/Get-ExampleConfiguration.ps1')
}

Describe 'Get-ExampleConfigurationPath' {
    It 'resolves the bundled configuration from the source layout' {
        $expectedPath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'src/resources/greeting-config.json'))

        Get-ExampleConfigurationPath | Should -Be $expectedPath
    }

    It 'resolves the configuration from a built-module style resources folder when one is present' {
        $moduleRoot = Join-Path $TestDrive 'dist/NovaExampleModule'
        $resourceRoot = Join-Path $moduleRoot 'resources'
        $expectedPath = Join-Path $resourceRoot 'greeting-config.json'

        $null = New-Item -ItemType Directory -Path $resourceRoot -Force
        Set-Content -LiteralPath $expectedPath -Value '{"GreetingPrefix":"Hi","DefaultAudience":"Built user"}' -Encoding utf8 -NoNewline

        Get-ExampleConfigurationPath -BasePath $moduleRoot | Should -Be $expectedPath
    }

    It 'stops when the configuration file is missing from both source and built layouts' {
        $basePath = Join-Path (Join-Path $TestDrive 'missing-layout') 'private'
        $null = New-Item -ItemType Directory -Path $basePath -Force

        { Get-ExampleConfigurationPath -BasePath $basePath } | Should -Throw 'Example configuration not found.*'
    }
}

Describe 'Get-ExampleConfiguration' {
    It 'returns the bundled greeting configuration data' {
        $result = Get-ExampleConfiguration

        $result.GreetingPrefix | Should -Be 'Hello'
        $result.DefaultAudience | Should -Be 'Nova user'
        (Split-Path -Leaf $result.ConfigurationPath) | Should -Be 'greeting-config.json'
    }
}
