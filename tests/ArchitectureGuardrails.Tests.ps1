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

    It 'public orchestration entrypoints keep delegating to their context and workflow helpers' {
        $testCases = @(
            [pscustomobject]@{Path = 'src/public/DeployNovaPackage.ps1'; ContextPattern = '\bGet-NovaPackageUploadWorkflowContext\b'; ActionPattern = '\bInvoke-NovaPackageUploadWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/InitializeNovaModule.ps1'; ContextPattern = '\bGet-NovaModuleInitializationWorkflowContext\b'; ActionPattern = '\bInvoke-NovaModuleInitializationWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/InstallNovaCli.ps1'; ContextPattern = '\bGet-NovaCliInstallWorkflowContext\b'; ActionPattern = '\bInvoke-NovaCliInstallWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/InvokeNovaBuild.ps1'; ContextPattern = '\bGet-NovaBuildWorkflowContext\b'; ActionPattern = '\bInvoke-NovaBuildWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/InvokeNovaCli.ps1'; ContextPattern = '\bGet-NovaCliInvocationContext\b'; ActionPattern = '\bInvoke-NovaCliCommandRoute\b'}
            [pscustomobject]@{Path = 'src/public/InvokeNovaRelease.ps1'; ContextPattern = '\bGet-NovaPublishWorkflowContext\b'; ActionPattern = '\bInvoke-NovaReleaseWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/NewNovaModulePackage.ps1'; ContextPattern = '\bGet-NovaPackageWorkflowContext\b'; ActionPattern = '\bInvoke-NovaPackageWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/PublishNovaModule.ps1'; ContextPattern = '\bGet-NovaPublishWorkflowContext\b'; ActionPattern = '\bInvoke-NovaPublishWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/SetNovaUpdateNotificationPreference.ps1'; ContextPattern = '\bGet-NovaUpdateNotificationPreferenceChangeContext\b'; ActionPattern = '\bInvoke-NovaUpdateNotificationPreferenceChange\b'}
            [pscustomobject]@{Path = 'src/public/TestNovaBuild.ps1'; ContextPattern = '\bGet-NovaTestWorkflowContext\b'; ActionPattern = '\bInvoke-NovaTestWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/UpdateNovaModuleTools.ps1'; ContextPattern = '\bGet-NovaModuleSelfUpdateWorkflowContext\b'; ActionPattern = '\bInvoke-NovaModuleSelfUpdateWorkflow\b'}
            [pscustomobject]@{Path = 'src/public/UpdateNovaModuleVersion.ps1'; ContextPattern = '\bGet-NovaVersionUpdateWorkflowContext\b'; ActionPattern = '\bInvoke-NovaVersionUpdateWorkflow\b'}
        )

        foreach ($testCase in $testCases) {
            $filePath = Join-Path $script:repoRoot $testCase.Path
            $content = Get-Content -LiteralPath $filePath -Raw

            $content | Should -Match $testCase.ContextPattern -Because "$( $testCase.Path ) should build or resolve its workflow/context state before orchestration"
            $content | Should -Match $testCase.ActionPattern -Because "$( $testCase.Path ) should delegate execution to its workflow or routing helper"
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
