BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:srcRoot = Join-Path $script:repoRoot 'src'
    $script:findMatches = {
        param(
            [Parameter(Mandatory)][string]$Pattern,
            [Parameter(Mandatory)][string]$RootPath
        )

        $matches = foreach ($file in (Get-ChildItem -LiteralPath $RootPath -Filter '*.ps1' -Recurse -File)) {
            foreach ($match in (Select-String -Path $file.FullName -Pattern $Pattern)) {
                [pscustomobject]@{
                    Path = ([System.IO.Path]::GetRelativePath($script:repoRoot, $file.FullName)).Replace('\', '/')
                    Line = $match.LineNumber
                    Text = $match.Line.Trim()
                }
            }
        }

        return @($matches)
    }
    $script:getMatchedPaths = {
        param([AllowNull()][object[]]$MatchList)

        if ($null -eq $MatchList) {
            return @()
        }

        return @($MatchList | ForEach-Object Path | Sort-Object -Unique)
    }
    $script:formatMatches = {
        param([AllowNull()][object[]]$MatchList)

        if ($null -eq $MatchList) {
            return 'No matches.'
        }

        return ($MatchList | ForEach-Object {
            "$( $_.Path ):$( $_.Line ) -> $( $_.Text )"
        }) -join [Environment]::NewLine
    }
}

Describe 'Architecture guardrails' {
    It 'public commands stay free of raw infrastructure primitives' {
        $matches = & $script:findMatches -RootPath (Join-Path $script:srcRoot 'public') -Pattern 'ConvertFrom-Json|ConvertTo-Json|Invoke-WebRequest|Invoke-RestMethod|Update-Module|&\s*git\b|\$env:|GetEnvironmentVariable\('

        $matches | Should -BeNullOrEmpty -Because (& $script:formatMatches -MatchList $matches)
    }

    It 'direct environment-variable access stays centralized in the shared helper' {
        $matches = & $script:findMatches -RootPath $script:srcRoot -Pattern '\$env:|GetEnvironmentVariable\('
        $actual = & $script:getMatchedPaths -MatchList $matches
        $expected = @('src/private/shared/GetNovaEnvironmentVariableValue.ps1')

        (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) | Should -BeNullOrEmpty -Because (($actual -join ', '), (& $script:formatMatches -MatchList $matches) -join [Environment]::NewLine)
    }

    It 'direct git execution stays centralized in the shared git adapter' {
        $matches = & $script:findMatches -RootPath $script:srcRoot -Pattern '&\s*git\b'
        $actual = & $script:getMatchedPaths -MatchList $matches
        $expected = @('src/private/shared/InvokeNovaGitCommand.ps1')

        (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) | Should -BeNullOrEmpty -Because (($actual -join ', '), (& $script:formatMatches -MatchList $matches) -join [Environment]::NewLine)
    }

    It 'raw upload requests stay behind the package request adapter' {
        $matches = & $script:findMatches -RootPath $script:srcRoot -Pattern '\bInvoke-WebRequest\b'
        $actual = & $script:getMatchedPaths -MatchList $matches
        $expected = @('src/private/package/InvokeNovaPackageUploadRequest.ps1')

        (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) | Should -BeNullOrEmpty -Because (($actual -join ', '), (& $script:formatMatches -MatchList $matches) -join [Environment]::NewLine)
    }

    It 'self-update execution stays behind the update command adapter' {
        $matches = & $script:findMatches -RootPath $script:srcRoot -Pattern '^\s*(?:return\s+)?Update-Module\b'
        $actual = & $script:getMatchedPaths -MatchList $matches
        $expected = @('src/private/update/InvokeNovaModuleUpdateCommand.ps1')

        (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) | Should -BeNullOrEmpty -Because (($actual -join ', '), (& $script:formatMatches -MatchList $matches) -join [Environment]::NewLine)
    }

    It 'public command files use only their approved Nova helper surface' {
        $testCases = @(
            [pscustomobject]@{Path = 'src/public/DeployNovaPackage.ps1'; ExpectedHelpers = @('Get-NovaPackageUploadWorkflowContext', 'Get-NovaProjectInfo', 'Invoke-NovaPackageUploadWorkflow', 'New-NovaPackageUploadDynamicParameterDictionary', 'New-NovaPackageUploadOption')}
            [pscustomobject]@{Path = 'src/public/GetNovaProjectInfo.ps1'; ExpectedHelpers = @('Get-NovaProjectInfoContext', 'Get-NovaProjectInfoResult')}
            [pscustomobject]@{Path = 'src/public/GetNovaUpdateNotificationPreference.ps1'; ExpectedHelpers = @('Get-NovaUpdateNotificationPreferenceStatus')}
            [pscustomobject]@{Path = 'src/public/InitializeNovaModule.ps1'; ExpectedHelpers = @('Get-NovaModuleInitializationWorkflowContext', 'Invoke-NovaModuleInitializationWorkflow')}
            [pscustomobject]@{Path = 'src/public/InstallNovaCli.ps1'; ExpectedHelpers = @('Get-NovaCliInstallWorkflowContext', 'Invoke-NovaCliInstallWorkflow', 'Write-NovaModuleReleaseNotesLink')}
            [pscustomobject]@{Path = 'src/public/InvokeNovaBuild.ps1'; ExpectedHelpers = @('Get-NovaBuildWorkflowContext', 'Invoke-NovaBuildWorkflow')}
            [pscustomobject]@{Path = 'src/public/InvokeNovaCli.ps1'; ExpectedHelpers = @('Get-NovaCliInvocationContext', 'Invoke-NovaCliCommandRoute')}
            [pscustomobject]@{Path = 'src/public/InvokeNovaRelease.ps1'; ExpectedHelpers = @('Get-NovaProjectInfo', 'Get-NovaPublishWorkflowContext', 'Get-NovaShouldProcessForwardingParameter', 'Invoke-NovaReleaseWorkflow', 'Write-NovaPublishWorkflowContext')}
            [pscustomobject]@{Path = 'src/public/NewNovaModulePackage.ps1'; ExpectedHelpers = @('Get-NovaPackageWorkflowContext', 'Get-NovaShouldProcessForwardingParameter', 'Invoke-NovaPackageWorkflow')}
            [pscustomobject]@{Path = 'src/public/PublishNovaModule.ps1'; ExpectedHelpers = @('Get-NovaDynamicDeliveryParameterDictionary', 'Get-NovaProjectInfo', 'Get-NovaPublishWorkflowContext', 'Get-NovaShouldProcessForwardingParameter', 'Invoke-NovaPublishWorkflow', 'Write-NovaPublishWorkflowContext')}
            [pscustomobject]@{Path = 'src/public/SetNovaUpdateNotificationPreference.ps1'; ExpectedHelpers = @('Get-NovaUpdateNotificationPreferenceChangeContext', 'Invoke-NovaUpdateNotificationPreferenceChange')}
            [pscustomobject]@{Path = 'src/public/TestNovaBuild.ps1'; ExpectedHelpers = @('Get-NovaTestWorkflowContext', 'Invoke-NovaTestWorkflow', 'New-NovaTestDynamicParameterDictionary')}
            [pscustomobject]@{Path = 'src/public/UpdateNovaModuleTools.ps1'; ExpectedHelpers = @('Complete-NovaModuleSelfUpdateResult', 'Confirm-NovaPrereleaseModuleUpdate', 'Get-NovaModuleSelfUpdateWorkflowContext', 'Invoke-NovaModuleSelfUpdateWorkflow', 'Write-NovaModuleReleaseNotesLink')}
            [pscustomobject]@{Path = 'src/public/UpdateNovaModuleVersion.ps1'; ExpectedHelpers = @('Get-NovaVersionUpdateWorkflowContext', 'Invoke-NovaVersionUpdateCiActivation', 'Invoke-NovaVersionUpdateWorkflow', 'Write-NovaVersionUpdateResultOutput')}
        )
        $expectedPaths = @($testCases | ForEach-Object Path | Sort-Object)
        $actualPaths = @(
        Get-ChildItem -LiteralPath (Join-Path $script:srcRoot 'public') -Filter '*.ps1' -File |
                ForEach-Object {([System.IO.Path]::GetRelativePath($script:repoRoot, $_.FullName)).Replace('\', '/')} |
                Sort-Object
        )

        (Compare-Object -ReferenceObject $expectedPaths -DifferenceObject $actualPaths) | Should -BeNullOrEmpty -Because "Public command allowlist should stay in sync with src/public. Expected: $( $expectedPaths -join ', ' ) | Actual: $( $actualPaths -join ', ' )"

        foreach ($testCase in $testCases) {
            $filePath = Join-Path $script:repoRoot $testCase.Path
            $null = $tokens = $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$parseErrors)
            $actualHelpers = @(
            $ast.FindAll({param($node) $node -is [System.Management.Automation.Language.CommandAst]}, $true) |
                    ForEach-Object {$_.GetCommandName()} |
                    Where-Object {$_ -like '*Nova*'} |
                    Sort-Object -Unique
            )
            $expectedHelpers = @($testCase.ExpectedHelpers | Sort-Object -Unique)

            (Compare-Object -ReferenceObject $expectedHelpers -DifferenceObject $actualHelpers) | Should -BeNullOrEmpty -Because "$( $testCase.Path ) should only use its approved Nova helper surface. Expected: $( $expectedHelpers -join ', ' ) | Actual: $( $actualHelpers -join ', ' )"
        }
    }

    It 'project.json persistence stays limited to the shared writer and its expected callers' {
        $matches = & $script:findMatches -RootPath $script:srcRoot -Pattern '\bWrite-ProjectJsonData\b'
        $actual = & $script:getMatchedPaths -MatchList $matches
        $expected = @(
            'src/private/release/SetNovaModuleVersion.ps1'
            'src/private/scaffold/WriteNovaModuleProjectJson.ps1'
            'src/private/shared/Write-ProjectJsonData.ps1'
        )

        (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) | Should -BeNullOrEmpty -Because (($actual -join ', '), (& $script:formatMatches -MatchList $matches) -join [Environment]::NewLine)
    }
}
