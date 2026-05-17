BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/CopyProjectResource.ps1')

    . (Join-Path $PSScriptRoot 'CopyProjectResource.TestSupport.ps1')
}

Describe 'Copy-ProjectResource' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $script:resourceFolder = Join-Path $script:root 'resources'
        $null = New-Item -ItemType Directory -Path $script:resourceFolder -Force
        Set-Content -LiteralPath (Join-Path $script:resourceFolder 'item.txt') -Value 'x'
        $script:projectData = [pscustomobject]@{
            ProjectRoot = $script:root
            OutputModuleDir = (Join-Path $script:root 'dist')
            CopyResourcesToModuleRoot = $false
        }
        Mock Get-NovaBuildProjectInfo {return $script:projectData}
        Mock Get-ProjectResourceFolderPath {return $script:resourceFolder}
        Mock Get-ProjectResourceItemList {return @(Get-ChildItem -LiteralPath $script:resourceFolder)}
        Mock Copy-ProjectResourceContentToModuleRoot {}
        Mock Copy-ProjectResourceFolderToOutputModuleDir {}
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns silently when the resource folder does not exist' {
        Mock Get-ProjectResourceFolderPath {return (Join-Path $script:root 'missing')}

        Copy-ProjectResource

        Assert-MockCalled Copy-ProjectResourceContentToModuleRoot -Times 0
        Assert-MockCalled Copy-ProjectResourceFolderToOutputModuleDir -Times 0
    }

    It 'returns silently when the resource folder is empty' {
        Mock Get-ProjectResourceItemList {return @()}

        Copy-ProjectResource

        Assert-MockCalled Copy-ProjectResourceContentToModuleRoot -Times 0
        Assert-MockCalled Copy-ProjectResourceFolderToOutputModuleDir -Times 0
    }

    It 'flattens resources when CopyResourcesToModuleRoot is true' {
        $script:projectData.CopyResourcesToModuleRoot = $true

        Copy-ProjectResource

        Assert-MockCalled Copy-ProjectResourceContentToModuleRoot -Times 1
        Assert-MockCalled Copy-ProjectResourceFolderToOutputModuleDir -Times 0
    }

    It 'copies the resource folder when CopyResourcesToModuleRoot is false' {
        Copy-ProjectResource

        Assert-MockCalled Copy-ProjectResourceFolderToOutputModuleDir -Times 1
        Assert-MockCalled Copy-ProjectResourceContentToModuleRoot -Times 0
    }
}
