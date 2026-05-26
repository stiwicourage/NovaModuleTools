BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:srcRoot = Join-Path $script:repoRoot 'src/private'
    $script:testRoot = Join-Path $script:repoRoot 'tests/private'
}

Describe 'Progress workflow guardrails' {
    It 'each private workflow that writes progress has a mirrored test file' {
        $progressWorkflowPaths = @(
            Get-ChildItem -LiteralPath $script:srcRoot -Filter '*.ps1' -Recurse -File |
                Where-Object {
                    Select-String -Path $_.FullName -Pattern '\bWrite-Progress\b' -Quiet
                } |
                ForEach-Object {
                    ([System.IO.Path]::GetRelativePath($script:repoRoot, $_.FullName)).Replace('\', '/')
                } |
                Sort-Object
        )

        $missingTests = foreach ($sourcePath in $progressWorkflowPaths) {
            $expectedTestPath = $sourcePath.Replace('src/private/', 'tests/private/').Replace('.ps1', '.Tests.ps1')
            if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot $expectedTestPath))) {
                $expectedTestPath
            }
        }

        $missingTests | Should -BeNullOrEmpty -Because "Missing mirrored progress tests: $( $missingTests -join ', ' )"
    }
}
