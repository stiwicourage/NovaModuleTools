BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/WriteNovaVsCodeSettings.ps1')
}

Describe 'Write-NovaVsCodeSettings' {
    It 'does nothing when module version is not available (dot-sourced context)' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCode-$([guid]::NewGuid())")
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        try {
            Write-NovaVsCodeSettings -ProjectRoot $tempDir
            Test-Path -LiteralPath (Join-Path $tempDir '.vscode/settings.json') | Should -BeFalse
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Describe 'with module version available' {
        BeforeAll {
            $root    = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            $srcFile = Join-Path $root 'src/private/scaffold/WriteNovaVsCodeSettings.ps1'
            $script:modDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCodeMod-$([guid]::NewGuid())")
            New-Item -ItemType Directory -Path $script:modDir -Force | Out-Null
            $psm1 = Join-Path $script:modDir 'NovaVsCodeTestMod.psm1'
            $psd1 = Join-Path $script:modDir 'NovaVsCodeTestMod.psd1'
            Set-Content -LiteralPath $psm1 -Value ". `"$srcFile`""
            New-ModuleManifest -Path $psd1 -RootModule 'NovaVsCodeTestMod.psm1' `
                -ModuleVersion '3.1.0' -FunctionsToExport @('Write-NovaVsCodeSettings') -Author 'Test'
            # Deviation from testing-policy: Import-Module -Global and InModuleScope are required
            # because $ExecutionContext.SessionState.Module.Version is $null when dot-sourced,
            # causing Write-NovaVsCodeSettings to return early as a no-op. A real module context
            # is the only way to exercise the positive paths. See the same pattern in
            # WriteNovaModuleProjectJson.Tests.ps1.
            Import-Module $psd1 -Force -Global
        }

        AfterAll {
            Get-Module 'NovaVsCodeTestMod' | Remove-Module -Force -ErrorAction SilentlyContinue
            Remove-Item $script:modDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'creates .vscode/settings.json with the versioned schema URL' {
            $projDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCodeProj-$([guid]::NewGuid())")
            New-Item -ItemType Directory -Path $projDir -Force | Out-Null
            try {
                InModuleScope 'NovaVsCodeTestMod' -Parameters @{ProjectDir = $projDir} {
                    param($ProjectDir)
                    Write-NovaVsCodeSettings -ProjectRoot $ProjectDir
                }
                $settingsFile = Join-Path $projDir '.vscode/settings.json'
                Test-Path -LiteralPath $settingsFile | Should -BeTrue
                $content = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
                $entry = $content['json.schemas'][0]
                $entry['fileMatch'] | Should -Contain '/project.json'
                $entry['url'] | Should -Be 'https://www.novamoduletools.com/schema/v3/project.json'
            } finally {
                Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'adds schema entry to existing settings.json via the Add dispatch path' {
            $projDir      = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCodeProj-$([guid]::NewGuid())")
            $vsCodeDir    = Join-Path $projDir '.vscode'
            $settingsFile = Join-Path $vsCodeDir 'settings.json'
            New-Item -ItemType Directory -Path $vsCodeDir -Force | Out-Null
            '{"editor.tabSize": 4}' | Set-Content -LiteralPath $settingsFile -Encoding utf8NoBOM
            try {
                InModuleScope 'NovaVsCodeTestMod' -Parameters @{ProjectDir = $projDir} {
                    param($ProjectDir)
                    Write-NovaVsCodeSettings -ProjectRoot $ProjectDir
                }
                Test-Path -LiteralPath $settingsFile | Should -BeTrue
                $content = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
                ($content['json.schemas'] | Where-Object { $_['fileMatch'] -contains '/project.json' }) |
                    Should -Not -BeNullOrEmpty
            } finally {
                Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'New-NovaVsCodeSettingsFile' {
    BeforeAll {
        $script:tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCode-$([guid]::NewGuid())")
        New-Item -ItemType Directory -Path $script:tempDir -Force | Out-Null
    }

    AfterAll {
        Remove-Item $script:tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates .vscode directory and settings.json with the schema entry' {
        $vsCodeDir    = Join-Path $script:tempDir '.vscode'
        $settingsFile = Join-Path $vsCodeDir 'settings.json'
        New-NovaVsCodeSettingsFile -VsCodeDir $vsCodeDir -SettingsFile $settingsFile -SchemaUrl 'https://example.com/schema/v3/project.json'
        Test-Path -LiteralPath $settingsFile | Should -BeTrue
        $content = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
        $entry   = $content['json.schemas'][0]
        $entry['fileMatch'] | Should -Contain '/project.json'
        $entry['url'] | Should -Be 'https://example.com/schema/v3/project.json'
    }

    It 'reuses existing .vscode directory when it already exists' {
        $vsCodeDir    = Join-Path $script:tempDir '.vscode-existing'
        New-Item -ItemType Directory -Path $vsCodeDir -Force | Out-Null
        $settingsFile = Join-Path $vsCodeDir 'settings.json'
        New-NovaVsCodeSettingsFile -VsCodeDir $vsCodeDir -SettingsFile $settingsFile -SchemaUrl 'https://example.com/schema/v3/project.json'
        Test-Path -LiteralPath $settingsFile | Should -BeTrue
    }
}

Describe 'Add-NovaVsCodeJsonSchemaEntry' {
    BeforeAll {
        $script:tempDir2 = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaVsCode-$([guid]::NewGuid())")
        New-Item -ItemType Directory -Path $script:tempDir2 -Force | Out-Null
    }

    AfterAll {
        Remove-Item $script:tempDir2 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'adds entry when json.schemas key is missing' {
        $file = Join-Path $script:tempDir2 'settings-no-key.json'
        '{"editor.tabSize": 4}' | Set-Content -LiteralPath $file -Encoding utf8NoBOM
        Add-NovaVsCodeJsonSchemaEntry -SettingsFile $file -SchemaUrl 'https://example.com/v3/project.json'
        $content = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json -AsHashtable
        $content['json.schemas'].Count | Should -Be 1
        $content['json.schemas'][0]['fileMatch'] | Should -Contain '/project.json'
    }

    It 'adds entry when json.schemas exists with no project.json mapping' {
        $file = Join-Path $script:tempDir2 'settings-other-schemas.json'
        @{ 'json.schemas' = @(@{ fileMatch = @('*.schema.json'); url = 'https://other.com/schema.json' }) } |
            ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $file -Encoding utf8NoBOM
        Add-NovaVsCodeJsonSchemaEntry -SettingsFile $file -SchemaUrl 'https://example.com/v3/project.json'
        $content = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json -AsHashtable
        $content['json.schemas'].Count | Should -Be 2
        ($content['json.schemas'] | Where-Object { $_['fileMatch'] -contains '/project.json' }) | Should -Not -BeNullOrEmpty
    }

    It 'skips silently when /project.json mapping already exists' {
        $file = Join-Path $script:tempDir2 'settings-already-mapped.json'
        @{ 'json.schemas' = @(@{ fileMatch = @('/project.json'); url = 'https://custom.com/schema.json' }) } |
            ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $file -Encoding utf8NoBOM
        $before = Get-Content -LiteralPath $file -Raw
        Add-NovaVsCodeJsonSchemaEntry -SettingsFile $file -SchemaUrl 'https://example.com/v3/project.json'
        Get-Content -LiteralPath $file -Raw | Should -Be $before
    }

    It 'skips silently when unanchored project.json mapping already exists' {
        $file = Join-Path $script:tempDir2 'settings-unanchored.json'
        @{ 'json.schemas' = @(@{ fileMatch = @('project.json'); url = 'https://custom.com/schema.json' }) } |
            ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $file -Encoding utf8NoBOM
        $before = Get-Content -LiteralPath $file -Raw
        Add-NovaVsCodeJsonSchemaEntry -SettingsFile $file -SchemaUrl 'https://example.com/v3/project.json'
        Get-Content -LiteralPath $file -Raw | Should -Be $before
    }
}
