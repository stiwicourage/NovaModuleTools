BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetProjectScriptFiles.ps1')

    function Get-OrderedScriptFileForDirectory {param([string]$Directory, [string]$ProjectRoot, [bool]$Recurse)}
}

Describe 'Get-ProjectScriptFile' {
    It 'concatenates classes, public, then private script files in that order' {
        $info = [pscustomobject]@{
            ProjectRoot = '/proj'
            BuildRecursiveFolders = $true
            ClassesDir = '/proj/src/classes'
            PublicDir = '/proj/src/public'
            PrivateDir = '/proj/src/private'
        }

        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        try {
            $null = New-Item -ItemType Directory -Path $tempRoot -Force
            $classFile = Join-Path $tempRoot 'Class1.ps1'
            $pubFile = Join-Path $tempRoot 'Pub1.ps1'
            $privFile = Join-Path $tempRoot 'Priv1.ps1'
            foreach ($p in @($classFile, $pubFile, $privFile)) {Set-Content -LiteralPath $p -Value '#'}

            Mock Get-OrderedScriptFileForDirectory {
                switch -wildcard ($Directory) {
                    '*classes' {return @(Get-Item -LiteralPath $classFile)}
                    '*public' {return @(Get-Item -LiteralPath $pubFile)}
                    '*private' {return @(Get-Item -LiteralPath $privFile)}
                }
            }

            $result = Get-ProjectScriptFile -ProjectInfo $info

            $result.Count | Should -Be 3
            $result[0].Name | Should -Be 'Class1.ps1'
            $result[1].Name | Should -Be 'Pub1.ps1'
            $result[2].Name | Should -Be 'Priv1.ps1'
        } finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'passes Recurse:$false for the public directory only' {
        $info = [pscustomobject]@{
            ProjectRoot = '/proj'
            BuildRecursiveFolders = $true
            ClassesDir = '/proj/src/classes'
            PublicDir = '/proj/src/public'
            PrivateDir = '/proj/src/private'
        }
        Mock Get-OrderedScriptFileForDirectory {return @()}

        $null = Get-ProjectScriptFile -ProjectInfo $info

        Should -Invoke Get-OrderedScriptFileForDirectory -Times 1 -ParameterFilter {
            $Directory -like '*public' -and -not $Recurse
        }
        Should -Invoke Get-OrderedScriptFileForDirectory -Times 1 -ParameterFilter {
            $Directory -like '*classes' -and $Recurse
        }
        Should -Invoke Get-OrderedScriptFileForDirectory -Times 1 -ParameterFilter {
            $Directory -like '*private' -and $Recurse
        }
    }
}
