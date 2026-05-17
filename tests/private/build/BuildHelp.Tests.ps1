BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/BuildHelp.ps1')

    . (Join-Path $PSScriptRoot 'BuildHelp.TestSupport.ps1')
}

Describe 'Get-NovaHelpDocsDir' {
    It 'joins DocsDir and ProjectName' {
        $ctx = [pscustomobject]@{DocsDir = '/repo/docs'; ProjectName = 'MyMod'}
        Get-NovaHelpDocsDir -BuildProjectInfo $ctx | Should -Be ([IO.Path]::Combine('/repo/docs','MyMod'))
    }
}

Describe 'Get-NovaHelpMarkdownItem' {
    It 'returns the markdown files in the help docs dir' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $sub = Join-Path $tmp 'MyMod'
        New-Item -ItemType Directory -Path $sub -Force | Out-Null
        Set-Content -Path (Join-Path $sub 'X.md') -Value 'help'
        try {
            $ctx = [pscustomobject]@{DocsDir = $tmp; ProjectName = 'MyMod'}
            $files = @(Get-NovaHelpMarkdownItem -BuildProjectInfo $ctx)
            $files.Count | Should -Be 1
            $files[0].Name | Should -Be 'X.md'
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns nothing when help docs dir is missing' {
        $ctx = [pscustomobject]@{DocsDir = '/no/such/dir'; ProjectName = 'X'}
        Get-NovaHelpMarkdownItem -BuildProjectInfo $ctx | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaHelpBuildContext' {
    BeforeEach {
        $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
        Set-Content -Path (Join-Path $script:tmp 'X.md') -Value 'help'
        $script:fakeFiles = @(Get-Item (Join-Path $script:tmp 'X.md'))
    }
    AfterEach { Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }

    It 'returns null when no PlatyPS command help files are detected' {
        $ctx = [pscustomobject]@{DocsDir='/x'; ProjectName='Y'}
        Mock Measure-PlatyPSMarkdown { @() }
        Get-NovaHelpBuildContext -BuildProjectInfo $ctx -HelpMarkdownFiles $script:fakeFiles | Should -BeNullOrEmpty
    }
    It 'returns a context with command help files when detected' {
        $ctx = [pscustomobject]@{DocsDir='/x'; ProjectName='Y'}
        Mock Measure-PlatyPSMarkdown { @([pscustomobject]@{FilePath='X.md'; FileType='CommandHelp'}) }
        Mock Get-NovaHelpLocale { 'en-US' }
        $result = Get-NovaHelpBuildContext -BuildProjectInfo $ctx -HelpMarkdownFiles $script:fakeFiles
        $result.Locale | Should -Be 'en-US'
        $result.CommandHelpFiles.Count | Should -Be 1
    }
}

Describe 'Rename-NovaGeneratedHelpFolder' {
    It 'throws when expected generated dir is missing' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        try {
            $ctx = [pscustomobject]@{OutputModuleDir=$tmp; ProjectName='X'; DocsDir=$tmp}
            { Rename-NovaGeneratedHelpFolder -BuildProjectInfo $ctx -Locale 'en-US' } | Should -Throw -ErrorId 'Nova.Environment.GeneratedHelpDirectoryNotFound'
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    It 'renames the generated help dir to the locale' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $generated = Join-Path $tmp 'X'
        New-Item -ItemType Directory -Path $generated -Force | Out-Null
        try {
            $ctx = [pscustomobject]@{OutputModuleDir=$tmp; ProjectName='X'; DocsDir=$tmp}
            Rename-NovaGeneratedHelpFolder -BuildProjectInfo $ctx -Locale 'en-US'
            Test-Path (Join-Path $tmp 'en-US') | Should -BeTrue
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Assert-NovaPlatyPSAvailable' {
    It 'returns silently when PlatyPS is available' {
        Mock Get-Module { @([pscustomobject]@{Name='Microsoft.PowerShell.PlatyPS'}) }
        { Assert-NovaPlatyPSAvailable } | Should -Not -Throw
    }
    It 'stops when PlatyPS is unavailable' {
        Mock Get-Module { @() }
        { Assert-NovaPlatyPSAvailable } | Should -Throw -ErrorId 'Nova.Dependency.BuildHelpDependencyMissing'
    }
}

Describe 'Export-NovaGeneratedHelp' {
    It 'imports command help, exports maml to OutputModuleDir, and renames the generated folder to the locale' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $generated = Join-Path $tmp 'Y'
        New-Item -ItemType Directory -Path $generated -Force | Out-Null
        try {
            $ctx = [pscustomobject]@{OutputModuleDir=$tmp; ProjectName='Y'; DocsDir=$tmp}
            $helpContext = [pscustomobject]@{
                HelpMarkdownFiles = @()
                CommandHelpFiles = @([pscustomobject]@{FilePath = (Join-Path $tmp 'X.md')})
                Locale = 'en-US'
            }
            Mock Import-MarkdownCommandHelp {[CmdletBinding()] param([Parameter(ValueFromPipeline)]$Input, $Path) process {$_}}
            Mock Export-MamlCommandHelp {[CmdletBinding()] param([Parameter(ValueFromPipeline)]$Input, $OutputFolder) process {$script:exportFolder = $OutputFolder}}

            Export-NovaGeneratedHelp -BuildProjectInfo $ctx -HelpContext $helpContext

            Should -Invoke Import-MarkdownCommandHelp -Times 1
            Should -Invoke Export-MamlCommandHelp -Times 1
            Test-Path (Join-Path $tmp 'en-US') | Should -BeTrue
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Build-Help' {
    It 'returns when no help markdown files exist' {
        Mock Get-NovaBuildProjectInfo { [pscustomobject]@{DocsDir='/x'; ProjectName='Y'; OutputModuleDir='/o'} }
        Mock Get-NovaHelpMarkdownItem { @() }
        Mock Assert-NovaPlatyPSAvailable {}
        Mock Get-NovaHelpBuildContext {}
        Mock Export-NovaGeneratedHelp {}
        { Build-Help -ProjectInfo ([pscustomobject]@{}) } | Should -Not -Throw
        Assert-MockCalled Assert-NovaPlatyPSAvailable -Times 0
    }

    It 'handles PlatyPS help export when context is <Name>' -ForEach @(
        @{ Name = 'missing'; HelpContext = $null; ExpectedExportCalls = 0 }
        @{ Name = 'available'; HelpContext = [pscustomobject]@{HelpMarkdownFiles=@(); CommandHelpFiles=@(); Locale='en-US'}; ExpectedExportCalls = 1 }
    ) {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        Set-Content -Path (Join-Path $tmp 'X.md') -Value 'help'
        try {
            Mock Get-NovaBuildProjectInfo { [pscustomobject]@{DocsDir='/x'; ProjectName='Y'; OutputModuleDir='/o'} }
            Mock Get-NovaHelpMarkdownItem { @(Get-Item (Join-Path $tmp 'X.md')) }
            Mock Assert-NovaPlatyPSAvailable {}
            $script:buildHelpContext = $HelpContext
            Mock Get-NovaHelpBuildContext { $script:buildHelpContext }
            Mock Export-NovaGeneratedHelp {}
            Build-Help -ProjectInfo ([pscustomobject]@{})
            Assert-MockCalled Export-NovaGeneratedHelp -Times $ExpectedExportCalls
        } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
