BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetDuplicateFunctionSourceLine.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/FormatDuplicateFunctionErrorMessage.ps1')

    function New-TestDuplicateOccurrence {
        param(
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][int]$Line
        )

        return [pscustomobject]@{
            Name = $Name
            Extent = [pscustomobject]@{
                StartLineNumber = $Line
            }
        }
    }
}

Describe 'Format-DuplicateFunctionErrorMessage' {
    It 'formats duplicate groups, dist lines, and source locations in sorted order' {
        $duplicateGroup = @(
            [pscustomobject]@{
                Name = 'Get-Zeta'
                Group = @(
                    New-TestDuplicateOccurrence -Name 'Get-Zeta' -Line 12
                    New-TestDuplicateOccurrence -Name 'Get-Zeta' -Line 4
                )
            }
            [pscustomobject]@{
                Name = 'Get-Alpha'
                Group = @(
                    New-TestDuplicateOccurrence -Name 'Get-Alpha' -Line 8
                )
            }
        )
        $sourceIndex = @{
            'Get-Zeta' = @(
                [pscustomobject]@{Path = 'src/public/GetZeta.ps1'; Line = 9}
                [pscustomobject]@{Path = 'src/private/GetZeta.ps1'; Line = 2}
            )
            'Get-Alpha' = @(
                [pscustomobject]@{Path = 'src/public/GetAlpha.ps1'; Line = 5}
            )
        }

        $message = Format-DuplicateFunctionErrorMessage -Psm1Path '/repo/dist/NovaModuleTools.psm1' -DuplicateGroup $duplicateGroup -SourceIndex $sourceIndex
        $lines = $message -split "`n"

        $lines | Should -Be @(
            'Duplicate top-level function names detected in built module: /repo/dist/NovaModuleTools.psm1'
            ''
            '- Get-Alpha'
            '  - dist line 8'
            '  - source files:'
            '    - src/public/GetAlpha.ps1:5'
            ''
            '- Get-Zeta'
            '  - dist line 4'
            '  - dist line 12'
            '  - source files:'
            '    - src/private/GetZeta.ps1:2'
            '    - src/public/GetZeta.ps1:9'
        )
    }
}
