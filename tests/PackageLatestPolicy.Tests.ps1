$script:remainingHelperCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingHelperCoverage.TestSupport.ps1')).Path
$global:packageLatestPolicyTestSupportFunctionNameList = @(
    'Initialize-TestNovaPackageProjectLayout',
    'Get-TestNovaPackageProjectInfo'
)

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $here 'RemainingHelperCoverage.TestSupport.ps1')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    $script:metadataProjectLayout = [pscustomobject]@{
        ProjectRoot = '/tmp/project'
        OutputModuleDir = '/tmp/project/dist/PackageProject'
        PackageOutputDir = '/tmp/project/artifacts/packages'
    }
    $script:metadataPackageTypes = @('NuGet', 'Zip')

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
    . $testSupportPath
    foreach ($functionName in $global:packageLatestPolicyTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
}

Describe 'Package latest policy behavior' {
    It 'Get-NovaProjectInfo normalizes Package.Latest policies and legacy booleans' -ForEach @(
        @{Name = 'legacy-true'; Latest = $true; Expected = 'always'}
        @{Name = 'legacy-false'; Latest = $false; Expected = 'never'}
        @{Name = 'stable'; Latest = 'stable'; Expected = 'stable'}
        @{Name = 'always'; Latest = 'always'; Expected = 'always'}
        @{Name = 'never'; Latest = 'never'; Expected = 'never'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $projectRoot = Join-Path $TestDrive "package-latest-$($TestCase.Name)"
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = 'PackageLatestProject'
                Description = 'Package latest policy test'
                Version = '1.2.3'
                Manifest = [ordered]@{
                    Author = 'Test Author'
                    PowerShellHostVersion = '7.4'
                    GUID = '88888888-8888-8888-8888-888888888888'
                }
                Package = [ordered]@{
                    Latest = $TestCase.Latest
                }
            } | ConvertTo-Json -Depth 4)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            $projectInfo = Get-NovaProjectInfo -Path $projectRoot

            $projectInfo.Package.Latest | Should -Be $TestCase.Expected
        }
    }

    It 'Test-NovaPackageLatestEnabled resolves latest policies, legacy booleans, and stable versions' {
        InModuleScope $script:moduleName {
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = 'always'} -Version '1.2.3-preview1' | Should -BeTrue
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = 'stable'} -Version '1.2.3' | Should -BeTrue
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = 'stable'} -Version '1.2.3-preview1' | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = $true} -Version '1.2.3-preview1' | Should -BeTrue
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = $false} -Version '1.2.3' | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings ([pscustomobject]@{Latest = 'never'}) -Version '1.2.3' | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings ([pscustomobject]@{Types = @('Zip')}) -Version '1.2.3' | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings $null -Version '1.2.3' | Should -BeFalse
        }
    }

    It 'ConvertTo-NovaPackageLatestPolicy normalizes valid values and rejects unsupported ones' {
        InModuleScope $script:moduleName {
            ConvertTo-NovaPackageLatestPolicy -Value $true | Should -Be 'always'
            ConvertTo-NovaPackageLatestPolicy -Value $false | Should -Be 'never'
            ConvertTo-NovaPackageLatestPolicy -Value 'Stable' | Should -Be 'stable'
            ConvertTo-NovaPackageLatestPolicy -Value 'always' | Should -Be 'always'
            ConvertTo-NovaPackageLatestPolicy -Value $null | Should -Be 'never'
            ConvertTo-NovaPackageLatestPolicy -Value '   ' | Should -Be 'never'

            $thrown = $null
            try {
                ConvertTo-NovaPackageLatestPolicy -Value 'preview'
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.InvalidPackageLatestPolicy'
        }
    }

    It 'Get-NovaPackageMetadataList resolves policy variants and legacy values' -ForEach @(
        @{
            Name = 'always-stable'
            Latest = 'always'
            Version = '2.3.4'
            ExpectedType = @('NuGet', 'NuGet', 'Zip', 'Zip')
            ExpectedLatest = @($false, $true, $false, $true)
            ExpectedPackageFileName = @(
                'PackageProject.2.3.4.nupkg',
                'PackageProject.latest.nupkg',
                'PackageProject.2.3.4.zip',
                'PackageProject.latest.zip'
            )
            ExpectedPackagePath = @(
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.latest.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip',
                '/tmp/project/artifacts/packages/PackageProject.latest.zip'
            )
        }
        @{
            Name = 'stable-preview'
            Latest = 'stable'
            Version = '2.3.4-preview1'
            ExpectedType = @('NuGet', 'Zip')
            ExpectedLatest = @($false, $false)
            ExpectedPackageFileName = @(
                'PackageProject.2.3.4-preview1.nupkg',
                'PackageProject.2.3.4-preview1.zip'
            )
            ExpectedPackagePath = @(
                '/tmp/project/artifacts/packages/PackageProject.2.3.4-preview1.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.2.3.4-preview1.zip'
            )
        }
        @{
            Name = 'legacy-true-preview'
            Latest = $true
            Version = '2.3.4-preview1'
            ExpectedType = @('NuGet', 'NuGet', 'Zip', 'Zip')
            ExpectedLatest = @($false, $true, $false, $true)
            ExpectedPackageFileName = @(
                'PackageProject.2.3.4-preview1.nupkg',
                'PackageProject.latest.nupkg',
                'PackageProject.2.3.4-preview1.zip',
                'PackageProject.latest.zip'
            )
            ExpectedPackagePath = @(
                '/tmp/project/artifacts/packages/PackageProject.2.3.4-preview1.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.latest.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.2.3.4-preview1.zip',
                '/tmp/project/artifacts/packages/PackageProject.latest.zip'
            )
        }
    ) {
        $projectInfo = Get-TestNovaPackageProjectInfo -Layout $script:metadataProjectLayout -CleanOutputDirectory $true -PackageTypes $script:metadataPackageTypes -Version $_.Version -Latest $_.Latest
        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = $projectInfo
            TestCase = $_
        } {
            param($ProjectInfo, $TestCase)

            $result = @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo)

            $result.Type | Should -Be $TestCase.ExpectedType
            $result.Latest | Should -Be $TestCase.ExpectedLatest
            $result.PackageFileName | Should -Be $TestCase.ExpectedPackageFileName
            $result.PackagePath | Should -Be $TestCase.ExpectedPackagePath
        }
    }

    It 'New-NovaPackageArtifacts skips latest-named artifacts when Package.Latest is stable and the version is preview' {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive 'stable-latest-preview-package-project')

        $result = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -PackageTypes $script:metadataPackageTypes -Latest 'stable' -Version '2.3.4-preview1')
        } {
            param($ProjectInfo)

            $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo)
            @(New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $packageMetadataList)
        }

        $result.Type | Should -Be @('NuGet', 'Zip')
        $result.Latest | Should -Be @($false, $false)
        $result.PackageFileName | Should -Be @(
            'PackageProject.2.3.4-preview1.nupkg',
            'PackageProject.2.3.4-preview1.zip'
        )
    }
}
