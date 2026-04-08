BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'release' 'SemanticReleaseSupport.ps1')
}

Describe 'Semantic release support' {
    It 'moves unreleased notes into a versioned changelog section and preserves headings in Unreleased' {
        $date = '2026-04-08'
        $changelog = @'
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Added semantic-release support

### Fixed
- Fixed CI reporting

## [1.7.0] - 2026-03-01

### Added
- Previous release notes
'@

        $updated = Format-ReleaseChangelogText -Text $changelog -Version '2.0.0' -Date $date
        $unreleasedBody = (Get-UnreleasedSectionMatch -Text $updated).Groups['body'].Value

        $updated | Should -Match '## \[2\.0\.0\] - 2026-04-08'
        $updated | Should -Match '(?s)## \[2\.0\.0\] - 2026-04-08.*Added semantic-release support'
        $updated | Should -Match '(?s)## \[2\.0\.0\] - 2026-04-08.*Fixed CI reporting'
        $unreleasedBody | Should -Match '(?s)^\s*### Added\s+### Fixed\s*$'
        $unreleasedBody | Should -Not -Match 'Added semantic-release support'
    }

    It 'updates project.json version' {
        $projectFile = Join-Path $TestDrive 'project.json'
        @'
{
  "ProjectName": "NovaModuleTools",
  "Version": "1.7.2-preview",
  "Manifest": {
    "GUID": "11111111-1111-1111-1111-111111111111"
  }
}
'@ | Set-Content -LiteralPath $projectFile -Encoding utf8

        Write-ProjectJsonVersion -Path $projectFile -Version '2.0.0'

        $project = Get-Content -LiteralPath $projectFile -Raw | ConvertFrom-Json
        $project.Version | Should -Be '2.0.0'
    }
}


