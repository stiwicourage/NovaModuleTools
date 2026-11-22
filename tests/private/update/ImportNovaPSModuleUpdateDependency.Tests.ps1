BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ImportNovaPSModuleUpdateDependency.ps1')
    . (Join-Path $PSScriptRoot 'ImportNovaPSModuleUpdateDependency.TestSupport.ps1')
}

Describe 'Import-NovaPSModuleUpdateDependency' {
    BeforeEach {
        Mock Import-Module {}
        Mock Install-PSResource {}
        Mock Write-Message {}
    }

    It 'imports PSModuleUpdate with the supported minimum version when it is installed' {
        Mock Get-Module {[pscustomobject]@{Name = 'PSModuleUpdate'; Version = [version]'0.3.0'}}

        Import-NovaPSModuleUpdateDependency -Cmdlet (New-NovaTestShouldProcessCmdlet -Approve $true)

        Should -Invoke Install-PSResource -Times 0
        Should -Invoke Import-Module -Times 1 -ParameterFilter {$Name -eq 'PSModuleUpdate' -and $MinimumVersion -eq [version]'0.3.0'}
    }

    It 'installs PSModuleUpdate into CurrentUser when only an older version is available and the install is approved' {
        Mock Get-Module {[pscustomobject]@{Name = 'PSModuleUpdate'; Version = [version]'0.2.0'}}
        $cmdlet = New-NovaTestShouldProcessCmdlet -Approve $true

        Import-NovaPSModuleUpdateDependency -Cmdlet $cmdlet

        $cmdlet.Target | Should -Be 'PSModuleUpdate'
        Should -Invoke Install-PSResource -Times 1 -ParameterFilter {
            $Name -eq 'PSModuleUpdate' -and $Version -eq '[0.3.0,)' -and $Repository -eq 'PSGallery' -and $Scope -eq 'CurrentUser'
        }
        Should -Invoke Import-Module -Times 1
    }

    It 'stops with installation guidance when the dependency install is declined' {
        Mock Get-Module {}

        {Import-NovaPSModuleUpdateDependency -Cmdlet (New-NovaTestShouldProcessCmdlet -Approve $false)} |
                Should -Throw -ErrorId 'Nova.Dependency.PSModuleUpdateUnavailable' -ExpectedMessage '*Install-PSResource -Name PSModuleUpdate -Scope CurrentUser*'

        Should -Invoke Install-PSResource -Times 0
        Should -Invoke Import-Module -Times 0
    }

    It 'stops with the provider failure and installation guidance when the dependency install fails' {
        Mock Get-Module {}
        Mock Install-PSResource {throw 'gallery offline'}

        {Import-NovaPSModuleUpdateDependency -Cmdlet (New-NovaTestShouldProcessCmdlet -Approve $true)} |
                Should -Throw -ErrorId 'Nova.Dependency.PSModuleUpdateUnavailable' -ExpectedMessage '*gallery offline*Install-PSResource -Name PSModuleUpdate*'

        Should -Invoke Import-Module -Times 0
    }
}
