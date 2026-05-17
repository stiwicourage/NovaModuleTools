BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/AssertNovaPublicFunctionFileLayout.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
    function Get-FunctionNameFromFile {param($filePath)}
}

Describe 'Get-NovaPublicFunctionFileList' {
    It 'returns *.ps1 files from the public directory' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        Set-Content -Path (Join-Path $tmp 'A.ps1') -Value 'function A {}'
        Set-Content -Path (Join-Path $tmp 'B.txt') -Value 'not ps'
        try {
            $files = @(Get-NovaPublicFunctionFileList -ProjectInfo ([pscustomobject]@{PublicDir = $tmp}))
            $files.Count | Should -Be 1
            $files[0].Name | Should -Be 'A.ps1'
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns empty when public dir does not exist' {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        Get-NovaPublicFunctionFileList -ProjectInfo ([pscustomobject]@{PublicDir = $tmp}) | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaInvalidPublicFunctionFileList' {
    BeforeEach {
        $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
        Set-Content -Path (Join-Path $script:tmp 'Single.ps1') -Value 'x'
        Set-Content -Path (Join-Path $script:tmp 'Double.ps1') -Value 'x'
        Set-Content -Path (Join-Path $script:tmp 'None.ps1') -Value 'x'
    }
    AfterEach {
        Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'excludes files with exactly one top-level function' {
        Mock Get-FunctionNameFromFile {
            if ($filePath -like '*Single.ps1') { return @('Foo') }
            if ($filePath -like '*Double.ps1') { return @('A','B') }
            return @()
        }
        $invalid = Get-NovaInvalidPublicFunctionFileList -ProjectInfo ([pscustomobject]@{PublicDir=$script:tmp})
        ($invalid.FilePath | ForEach-Object { Split-Path -Leaf $_ }) | Should -Contain 'Double.ps1'
        ($invalid.FilePath | ForEach-Object { Split-Path -Leaf $_ }) | Should -Contain 'None.ps1'
        ($invalid.FilePath | ForEach-Object { Split-Path -Leaf $_ }) | Should -Not -Contain 'Single.ps1'
    }

    It 'returns relative paths when ProjectRoot is provided' {
        Mock Get-FunctionNameFromFile { @('A','B') }
        $invalid = Get-NovaInvalidPublicFunctionFileList -ProjectInfo ([pscustomobject]@{PublicDir=$script:tmp; ProjectRoot=$script:tmp})
        $invalid[0].FilePath | Should -Not -Match '^[/\\]'
    }
}

Describe 'Format-NovaPublicFunctionFileValidationMessage' {
    It 'lists invalid files with their function names' {
        $list = @(
            [pscustomobject]@{FilePath='src/public/A.ps1'; FunctionNameList=@('A','B')}
            [pscustomobject]@{FilePath='src/public/Empty.ps1'; FunctionNameList=@()}
        )
        $msg = Format-NovaPublicFunctionFileValidationMessage -InvalidFileList $list
        $msg | Should -Match 'src/public/A\.ps1: A, B'
        $msg | Should -Match 'src/public/Empty\.ps1: <none>'
        $msg | Should -Match 'override-warning'
    }
}

Describe 'Assert-NovaPublicFunctionFileLayout' {
    It 'returns silently when no invalid files' {
        Mock Get-NovaInvalidPublicFunctionFileList { @() }
        { Assert-NovaPublicFunctionFileLayout -ProjectInfo ([pscustomobject]@{PublicDir='src/public'}) } | Should -Not -Throw
    }

    It 'warns and stops when invalid files exist' {
        Mock Get-NovaInvalidPublicFunctionFileList { @([pscustomobject]@{FilePath='x.ps1'; FunctionNameList=@('A','B')}) }
        Mock Write-Warning {}
        { Assert-NovaPublicFunctionFileLayout -ProjectInfo ([pscustomobject]@{PublicDir='src/public'}) } | Should -Throw -ErrorId 'Nova.Validation.PublicFunctionFileLayoutInvalid'
        Assert-MockCalled Write-Warning -Times 1
    }

    It 'warns and continues when OverrideWarningRequested' {
        Mock Get-NovaInvalidPublicFunctionFileList { @([pscustomobject]@{FilePath='x.ps1'; FunctionNameList=@('A','B')}) }
        Mock Write-Warning {}
        { Assert-NovaPublicFunctionFileLayout -ProjectInfo ([pscustomobject]@{PublicDir='src/public'}) -OverrideWarningRequested } | Should -Not -Throw
        Assert-MockCalled Write-Warning -Times 1
    }
}
