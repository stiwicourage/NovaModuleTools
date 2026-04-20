$global:novaCommandModelPackageUploadTestSupportFunctionNameList = @(
    'Get-TestNovaPackageUploadOptionValue'
    'Initialize-TestNovaPackageUploadLayout'
    'New-TestNovaPackageUploadProjectInfo'
    'New-TestNovaPackageArtifactFile'
    'New-TestNovaPackageArtifactSet'
)

function Get-TestNovaPackageUploadOptionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Options,
        [Parameter(Mandatory)][string]$Name,
        $DefaultValue = $null
    )

    if ( $Options.ContainsKey($Name)) {
        return $Options[$Name]
    }

    return $DefaultValue
}

function Initialize-TestNovaPackageUploadLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $packageOutputDir = Join-Path $ProjectRoot 'artifacts/packages'
    New-Item -ItemType Directory -Path $packageOutputDir -Force | Out-Null

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        PackageOutputDir = $packageOutputDir
    }
}

function New-TestNovaPackageUploadProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Layout,
        [hashtable]$Options = @{}
    )

    return [pscustomobject]@{
        ProjectName = 'PackageProject'
        Version = '2.3.4'
        Description = 'Package project description'
        ProjectRoot = $Layout.ProjectRoot
        OutputModuleDir = (Join-Path $Layout.ProjectRoot 'dist/PackageProject')
        Manifest = [ordered]@{
            Author = 'Author One'
            Tags = @('Nova', 'Packaging')
            ProjectUri = 'https://example.test/project'
            ReleaseNotes = 'https://example.test/release-notes'
            LicenseUri = 'https://example.test/license'
        }
        Package = [ordered]@{
            Id = 'PackageProject'
            Types = @(Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'PackageTypes' -DefaultValue @('Zip'))
            OutputDirectory = [ordered]@{
                Path = $Layout.PackageOutputDir
                Clean = $false
            }
            FileNamePattern = (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'FileNamePattern' -DefaultValue 'PackageProject*')
            PackageFileName = 'PackageProject.2.3.4.nupkg'
            Authors = 'Author One'
            Description = 'Package project description'
            Repositories = @(Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'Repositories' -DefaultValue @())
            Headers = [ordered]@{} + (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'Headers' -DefaultValue ([ordered]@{}))
            Auth = [ordered]@{} + (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'Auth' -DefaultValue ([ordered]@{}))
            RepositoryUrl = (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'RepositoryUrl')
            RawRepositoryUrl = (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'RawRepositoryUrl')
            UploadPath = (Get-TestNovaPackageUploadOptionValue -Options $Options -Name 'UploadPath')
        }
    }
}

function New-TestNovaPackageArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$Name
    )

    $path = Join-Path $Directory $Name
    'artifact' | Set-Content -LiteralPath $path -Encoding utf8
    return $path
}

function New-TestNovaPackageArtifactSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [string[]]$PackageType = @('NuGet', 'Zip'),
        [switch]$IncludeLatest
    )

    return @(
    foreach ($type in $PackageType) {
        $extension = if ($type -eq 'Zip') {
            '.zip'
        } else {
            '.nupkg'
        }
        New-TestNovaPackageArtifactFile -Directory $Directory -Name "PackageProject.2.3.4$extension"
        if ($IncludeLatest) {
            New-TestNovaPackageArtifactFile -Directory $Directory -Name "PackageProject.latest$extension"
        }
    }
    )
}

