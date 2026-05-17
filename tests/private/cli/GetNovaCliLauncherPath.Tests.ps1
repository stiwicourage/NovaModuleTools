BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliLauncherPath.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaCliLauncherPath' {
    It 'throws when Install-NovaCli is not registered' {
        Mock Get-Command {return $null}
        {Get-NovaCliLauncherPath} | Should -Throw '*Install-NovaCli command not found*'
    }

    It 'returns the resolved launcher path when found beside the command file' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $resourceDir = Join-Path $tempRoot 'resources'
        New-Item -ItemType Directory -Path $resourceDir -Force | Out-Null
        $launcher = Join-Path $resourceDir 'nova'
        Set-Content -LiteralPath $launcher -Value 'x'
        $commandFile = Join-Path $tempRoot 'Install-NovaCli.ps1'
        Set-Content -LiteralPath $commandFile -Value 'x'
        try {
            $scriptBlock = [pscustomobject]@{File = $commandFile}
            $fakeCommand = [pscustomobject]@{ScriptBlock = $scriptBlock}
            Mock Get-Command {return $fakeCommand}
            Get-NovaCliLauncherPath | Should -Be ([System.IO.Path]::GetFullPath($launcher))
        } finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
