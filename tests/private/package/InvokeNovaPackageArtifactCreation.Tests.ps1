BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageArtifactCreation.ps1')
    function New-NovaPackageArtifacts {param($ProjectInfo,$PackageMetadataList) ,@([pscustomobject]@{PackagePath='/a'})}
}

Describe 'Invoke-NovaPackageArtifactCreation' {
    It 'invokes New-NovaPackageArtifacts when available locally' {
        Mock New-NovaPackageArtifacts {,@([pscustomobject]@{PackagePath='/a'})}
        $ctx = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{}
            PackageMetadataList = @([pscustomobject]@{PackagePath='/a'})
            ModulePath = '/m'
        }
        $r = Invoke-NovaPackageArtifactCreation -WorkflowContext $ctx
        @($r).Count | Should -BeGreaterThan 0
        Should -Invoke New-NovaPackageArtifacts -Times 1
    }

    It 'falls back to importing the module when New-NovaPackageArtifacts is not in scope' {
        Mock Get-Command {return $null} -ParameterFilter {$Name -eq 'New-NovaPackageArtifacts'}
        $script:fallbackResult = @([pscustomobject]@{PackagePath='/b'})
        $fakeModule = New-Module -Name FakePackagingModule -ScriptBlock {
            function New-NovaPackageArtifacts {param($ProjectInfo, $PackageMetadataList) return @([pscustomobject]@{PackagePath='/b'})}
            Export-ModuleMember -Function New-NovaPackageArtifacts
        } | Import-Module -PassThru
        try {
            Mock Import-Module {return $fakeModule}.GetNewClosure()
            $ctx = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{}
                PackageMetadataList = @([pscustomobject]@{PackagePath='/b'})
                ModulePath = '/m'
            }
            $result = Invoke-NovaPackageArtifactCreation -WorkflowContext $ctx
            Should -Invoke Import-Module -Times 1
            @($result).Count | Should -BeGreaterThan 0
        } finally {
            Remove-Module FakePackagingModule -Force -ErrorAction SilentlyContinue
        }
    }
}
