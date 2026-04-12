BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'release' 'SemanticReleaseSupport.ps1')
}

Describe 'Semantic release support' {
    It 'loads the split support functions through the compatibility entrypoint' {
        $expectedFunctionList = @(
            'Get-ReleaseDateString'
            'Get-ReleaseRepositoryUrl'
            'ConvertTo-ReleaseTagName'
            'Read-JsonFile'
            'Write-JsonFile'
            'Write-ProjectJsonVersion'
            'Get-UnreleasedSectionMatch'
            'Get-ClearedUnreleasedBody'
            'Get-ChangelogReleaseVersionList'
            'Get-AvailableReleaseVersionList'
            'Get-OrderedReleaseVersionList'
            'Get-PreviousReleaseVersion'
            'Get-ChangelogWithoutReferenceFooter'
            'Get-ChangelogReferenceFooter'
            'Format-ReleaseChangelogText'
            'Write-ChangelogFileForRelease'
        )

        foreach ($functionName in $expectedFunctionList) {
            Get-Command -Name $functionName -CommandType Function -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }
    }

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

        $updated = Format-ReleaseChangelogText -Text $changelog -Version '2.0.0' -Date $date -AvailableReleaseVersions @('1.6.0', '1.7.0', '2.0.0')
        $unreleasedBody = (Get-UnreleasedSectionMatch -Text $updated).Groups['body'].Value

        $updated | Should -Match '## \[2\.0\.0\] - 2026-04-08'
        $updated | Should -Match '(?s)## \[2\.0\.0\] - 2026-04-08.*Added semantic-release support'
        $updated | Should -Match '(?s)## \[2\.0\.0\] - 2026-04-08.*Fixed CI reporting'
        $unreleasedBody | Should -Match '(?s)^\s*### Added\s+### Fixed\s*$'
        $unreleasedBody | Should -Not -Match 'Added semantic-release support'
        $updated | Should -Match '\[Unreleased\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_2\.0\.0\.\.\.HEAD'
        $updated | Should -Match '\[2\.0\.0\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.7\.0\.\.\.Version_2\.0\.0'
        $updated | Should -Match '\[1\.7\.0\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.6\.0\.\.\.Version_1\.7\.0'
    }

    It 'rebuilds changelog comparison links from release headings without duplicating old footer entries' {
        $changelog = @'
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

## [1.9.0] - 2026-04-10

### Added
- Current release notes

## [1.8.0] - 2026-04-08

### Added
- Previous release notes

[Unreleased]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.8.0...HEAD
[1.9.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.7.0...Version_1.9.0
[1.8.0]: https://github.com/stiwicourage/NovaModuleTools/releases/tag/Version_1.8.0
'@

        $footer = Get-ChangelogReferenceFooter -Text $changelog -AvailableReleaseVersions @('1.7.0', '1.8.0', '1.9.0')
        $updated = Format-ReleaseChangelogText -Text $changelog -Version '1.9.1' -Date '2026-04-12' -AvailableReleaseVersions @('1.7.0', '1.8.0', '1.9.0', '1.9.1')

        $footer | Should -Be @'
[Unreleased]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.9.0...HEAD
[1.9.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.8.0...Version_1.9.0
[1.8.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.7.0...Version_1.8.0
'@.TrimEnd()

        ([regex]::Matches($updated, '(?m)^\[Unreleased\]:').Count) | Should -Be 1
        $updated | Should -Match '\[Unreleased\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.9\.1\.\.\.HEAD'
        $updated | Should -Match '\[1\.9\.1\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.9\.0\.\.\.Version_1\.9\.1'
        $updated | Should -Match '\[1\.9\.0\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.8\.0\.\.\.Version_1\.9\.0'
        $updated | Should -Match '\[1\.8\.0\]: https://github\.com/stiwicourage/NovaModuleTools/compare/Version_1\.7\.0\.\.\.Version_1\.8\.0'
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


