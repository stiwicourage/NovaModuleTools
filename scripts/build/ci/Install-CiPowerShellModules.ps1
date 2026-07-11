param(
    [string[]]$ModuleName = @(
    'Pester',
    'NovaModuleTools',
    'KeepAChangelog'
)
)

Set-StrictMode -Version Latest

function Get-CiModuleInstallOption {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    if ($Name -eq 'Pester') {
        return [pscustomobject]@{
            RequiredVersion = '6.0.0'
            AllowPrerelease = $false
        }
    }

    return [pscustomobject]@{
        RequiredVersion = $null
        AllowPrerelease = $true
    }
}

function Get-InstalledCiModule {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    return Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
}

function Write-CiInstalledModule {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $installedModule = Get-InstalledCiModule -Name $Name
    if (-not $installedModule) {
        throw "Expected PowerShell module '$Name' to be installed, but no installed module record was found."
    }

    Write-Host "Installed PowerShell module '$( $installedModule.Name )' version '$( $installedModule.Version )' from '$( $installedModule.Repository )'."
}

function Test-CiModuleInstallSkip {
    param(
        [Parameter(Mandatory)][pscustomobject]$InstallOptions,
        $InstalledModule
    )

    if (-not $InstallOptions.RequiredVersion) {
        return $false
    }

    if (-not $InstalledModule) {
        return $false
    }

    return $InstalledModule.Version -eq [version]$InstallOptions.RequiredVersion
}

function Invoke-CiInstallModuleCommand {
    param(
        [Parameter(Mandatory)][hashtable]$InstallParams
    )

    Install-Module @InstallParams | Out-Null
}

function Install-CiModule {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $installOptions = Get-CiModuleInstallOption -Name $Name
    $installedModule = Get-InstalledCiModule -Name $Name
    if (Test-CiModuleInstallSkip -InstallOptions $installOptions -InstalledModule $installedModule) {
        Write-Host "Skipping PowerShell module '$Name' because required version '$( $installOptions.RequiredVersion )' is already installed."
        Write-CiInstalledModule -Name $Name
        return
    }

    $installParams = @{Name = $Name; Repository = 'PSGallery'; Scope = 'CurrentUser'; Force = $true; ErrorAction = 'Stop'}
    if ($installOptions.RequiredVersion) {
        $installParams.RequiredVersion = $installOptions.RequiredVersion
        Write-Host "Installing PowerShell module '$Name' version '$( $installOptions.RequiredVersion )'..."
    } else {
        $installParams.AllowPrerelease = $installOptions.AllowPrerelease
        Write-Host "Installing PowerShell module '$Name' with AllowPrerelease=$( $installOptions.AllowPrerelease )..."
    }

    Invoke-CiInstallModuleCommand -InstallParams $installParams
    Write-CiInstalledModule -Name $Name
}

function Set-CiRepositoryTrust {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ( $PSCmdlet.ShouldProcess('PSGallery', 'Set repository installation policy to Trusted')) {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
}

function Invoke-CiPowerShellModuleInstall {
    param(
        [string[]]$ModuleName = @()
    )

    Set-CiRepositoryTrust

    foreach ($name in $ModuleName) {
        Install-CiModule -Name $name
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-CiPowerShellModuleInstall -ModuleName $ModuleName
}
