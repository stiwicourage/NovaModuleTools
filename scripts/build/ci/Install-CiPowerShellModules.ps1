param(
    [string[]]$ModuleName = @(
    'NovaModuleTools'
)
)

Set-StrictMode -Version Latest

function Install-CiModule {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $repositoryName = 'PSGallery'
    Write-Host "Installing PowerShell module '$Name'..."
    Install-Module -Name $Name -Repository $repositoryName -AllowPrerelease -Scope CurrentUser -Force -ErrorAction Stop | Out-Null

    $installedModule = Get-InstalledModule -Name $Name -ErrorAction Stop |
            Sort-Object Version -Descending |
            Select-Object -First 1

    Write-Host "Installed PowerShell module '$( $installedModule.Name )' version '$( $installedModule.Version )' from '$( $installedModule.Repository )'."
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

foreach ($name in $ModuleName) {
    Install-CiModule -Name $name
}
