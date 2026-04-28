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
}
