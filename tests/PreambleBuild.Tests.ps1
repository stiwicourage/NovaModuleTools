$script:preambleBuildTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'BuildOptions.TestSupport.ps1')).Path
$global:preambleBuildTestSupportFunctionNameList = @(
    'New-TestProjectRoot'
    'Write-TestProjectJson'
    'Get-BuiltModuleFilePath'
    'Invoke-TestProjectBuild'
    'Get-BuiltModuleContent'
    'Get-InvokeNovaBuildErrorMessage'
    'New-TestProjectWithPreamble'
)

. $script:preambleBuildTestSupportPath

foreach ($functionName in $global:preambleBuildTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $buildOptionsTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'BuildOptions.TestSupport.ps1')).Path
    $functionNameList = $global:preambleBuildTestSupportFunctionNameList
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $distModuleDir = Join-Path $repoRoot "dist/$moduleName"

    . $buildOptionsTestSupportPath

    foreach ($functionName in $functionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built $moduleName module at: $distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $moduleName -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force
}

Describe 'Invoke-NovaBuild Preamble setting' {
    Context 'exact output with <Name>' -ForEach @(
        @{Name = 'missing Preamble'; ProjectName = 'PreambleMissing'; Preamble = $null; ExpectedContent = 'function Invoke-PublicTop { "public" }'}
        @{Name = 'empty Preamble'; ProjectName = 'PreambleEmpty'; Preamble = @(); ExpectedContent = 'function Invoke-PublicTop { "public" }'}
        @{Name = 'single-line Preamble'; ProjectName = 'PreambleSingle'; Preamble = @('Set-StrictMode -Version Latest'); ExpectedContent = 'Set-StrictMode -Version Latest'}
    ) {
        It 'writes the expected module preamble and spacing' {
            $root = if ($null -eq $Preamble) {
                New-TestProjectWithPreamble -TestDriveRoot $TestDrive -Name $ProjectName
            }
            else {
                New-TestProjectWithPreamble -TestDriveRoot $TestDrive -Name $ProjectName -Options @{Preamble = $Preamble}
            }

            $content = Get-BuiltModuleContent -ProjectRoot $root
            $newLine = [Environment]::NewLine
            $expected = switch ($ProjectName) {
                'PreambleSingle' {
                    $ExpectedContent + $newLine + $newLine + 'function Invoke-PublicTop { "public" }'
                }
                default {
                    $ExpectedContent
                }
            }

            $content | Should -Be ($expected + $newLine + $newLine + $newLine + $newLine)
        }
    }

    It 'multi-line Preamble preserves order and inserts a blank line before the rest of the module content' {
        $root = New-TestProjectWithPreamble -TestDriveRoot $TestDrive -Name 'PreambleMulti' -Options @{
            Preamble = @(
                '# Module initialization'
                'Set-StrictMode -Version Latest'
                "`$script:ModuleInitialized = `$true"
            )
        }
        $content = Get-BuiltModuleContent -ProjectRoot $root
        $newLine = [Environment]::NewLine
        $expectedStart = @(
            '# Module initialization'
            'Set-StrictMode -Version Latest'
            "`$script:ModuleInitialized = `$true"
            ''
            'function Invoke-PublicTop { "public" }'
        ) -join $newLine

        $content.StartsWith($expectedStart) | Should -BeTrue
    }

    It 'Preamble appears before all source markers when SetSourcePath=true' {
        $root = New-TestProjectWithPreamble -TestDriveRoot $TestDrive -Name 'PreambleWithSourcePath' -Options @{
            SetSourcePath = $true
            IncludeClassAndPrivate = $true
            Preamble = @(
                'Set-StrictMode -Version Latest'
                "`$script:ModuleInitialized = `$true"
            )
        }

        $content = Get-BuiltModuleContent -ProjectRoot $root
        $newLine = [Environment]::NewLine
        $firstMarker = '# Source: src/classes/nested/Thing.ps1'
        $expectedStart = @(
            'Set-StrictMode -Version Latest'
            "`$script:ModuleInitialized = `$true"
            ''
            $firstMarker
        ) -join $newLine

        $content.StartsWith($expectedStart) | Should -BeTrue
        $content.IndexOf('Set-StrictMode -Version Latest') | Should -BeLessThan $content.IndexOf($firstMarker)
    }

    Context 'invalid Preamble value <ProjectName>' -ForEach @(
        @{ProjectName = 'PreambleInvalidType'; Preamble = 'Set-StrictMode -Version Latest'; ExpectedPatterns = @('Preamble', 'string\[\]', 'Set-StrictMode -Version Latest', 'top-level project\.json array of strings')}
        @{ProjectName = 'PreambleInvalidItem'; Preamble = @('Set-StrictMode -Version Latest', 123); ExpectedPatterns = @('Preamble', 'string\[\]', 'index 1', '123', 'top-level project\.json array of strings')}
    ) {
        It 'fails build with a clear validation error' {
            $root = New-TestProjectWithPreamble -TestDriveRoot $TestDrive -Name $ProjectName -Options @{Preamble = $Preamble}
            $message = Get-InvokeNovaBuildErrorMessage -ProjectRoot $root

            foreach ($pattern in $ExpectedPatterns) {
                $message | Should -Match $pattern
            }
        }
    }
}







