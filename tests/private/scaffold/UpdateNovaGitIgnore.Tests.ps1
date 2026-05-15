BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Update-NovaGitIgnore' {
    It 'creates a default .gitignore when the file is missing' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'MissingGitIgnore'
            $gitIgnorePath = Join-Path $projectRoot '.gitignore'
            $managedLineList = @(
                '# CI/local test artifacts'
                'testResults.xml'
                'coverage.xml'
                'artifacts/'
                'dist/'
                'run.ps1'
                'reload.ps1'
            )
            $null = New-Item -ItemType Directory -Path $projectRoot -Force

            Update-NovaGitIgnore -ProjectRoot $projectRoot

            $content = Get-Content -LiteralPath $gitIgnorePath -Raw
            $expectedContent = (@($managedLineList) -join [Environment]::NewLine) + [Environment]::NewLine

            $content | Should -Be $expectedContent
        }
    }

    It 'appends only the missing managed entries and keeps existing content intact' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'MergedGitIgnore'
            $gitIgnorePath = Join-Path $projectRoot '.gitignore'
            $null = New-Item -ItemType Directory -Path $projectRoot -Force
            $existingContent = @(
                'node_modules/'
                'artifacts/'
            ) -join [Environment]::NewLine
            Set-Content -LiteralPath $gitIgnorePath -Value ($existingContent + [Environment]::NewLine) -Encoding utf8 -NoNewline

            Update-NovaGitIgnore -ProjectRoot $projectRoot

            $lineList = @(Get-Content -LiteralPath $gitIgnorePath)
            $lineList[0] | Should -Be 'node_modules/'
            $lineList[1] | Should -Be 'artifacts/'
            $lineList[2] | Should -Be ''
            $lineList[3] | Should -Be '# CI/local test artifacts'
            $lineList | Should -Contain 'testResults.xml'
            $lineList | Should -Contain 'coverage.xml'
            $lineList | Should -Contain 'dist/'
            $lineList | Should -Contain 'run.ps1'
            $lineList | Should -Contain 'reload.ps1'
            @($lineList | Where-Object {$_ -eq 'artifacts/'}).Count | Should -Be 1
        }
    }

    It 'uses exact line matching when deciding whether a managed entry is already present' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'ExactMatchGitIgnore'
            $gitIgnorePath = Join-Path $projectRoot '.gitignore'
            $null = New-Item -ItemType Directory -Path $projectRoot -Force
            $existingContent = @(
                '# CI/local test artifacts'
                'testResults.xml'
                'coverage.xml'
                'artifacts/'
                '/dist/'
                'run.ps1'
                'reload.ps1'
            ) -join [Environment]::NewLine
            Set-Content -LiteralPath $gitIgnorePath -Value ($existingContent + [Environment]::NewLine) -Encoding utf8 -NoNewline

            Update-NovaGitIgnore -ProjectRoot $projectRoot

            $lineList = @(Get-Content -LiteralPath $gitIgnorePath)
            $lineList | Should -Contain '/dist/'
            $lineList | Should -Contain 'dist/'
            @($lineList | Where-Object {$_ -eq 'dist/'}).Count | Should -Be 1
        }
    }

    It 'does not append duplicate managed entries when run more than once' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'IdempotentGitIgnore'
            $gitIgnorePath = Join-Path $projectRoot '.gitignore'
            $managedLineList = @(
                '# CI/local test artifacts'
                'testResults.xml'
                'coverage.xml'
                'artifacts/'
                'dist/'
                'run.ps1'
                'reload.ps1'
            )
            $null = New-Item -ItemType Directory -Path $projectRoot -Force

            Update-NovaGitIgnore -ProjectRoot $projectRoot
            Update-NovaGitIgnore -ProjectRoot $projectRoot

            $lineList = @(Get-Content -LiteralPath $gitIgnorePath)
            foreach ($managedLine in $managedLineList) {
                @($lineList | Where-Object {$_ -eq $managedLine}).Count | Should -Be 1
            }
        }
    }
}
