BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/UpdateNovaGitIgnore.ps1')
}

Describe 'Nova .gitignore helper functions' {
    It 'returns an empty line list when the existing content is empty' {
        @(Get-NovaGitIgnoreLineList -Content '').Count | Should -Be 0
    }

    It 'returns an empty string when converting an empty line list to content' {
        ConvertTo-NovaGitIgnoreContent -LineList @() | Should -Be ''
    }
}

Describe 'Update-NovaGitIgnore' {
    It 'creates a default .gitignore when the file is missing' {
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

    It 'appends only the missing managed entries and keeps existing content intact' {
        $projectRoot = Join-Path $TestDrive 'MergedGitIgnore'
        $gitIgnorePath = Join-Path $projectRoot '.gitignore'
        $null = New-Item -ItemType Directory -Path $projectRoot -Force
        $existingContent = @('node_modules/', 'artifacts/') -join [Environment]::NewLine
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

    It 'uses exact line matching when deciding whether a managed entry is already present' {
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

    It 'does not append duplicate managed entries when run more than once' {
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
