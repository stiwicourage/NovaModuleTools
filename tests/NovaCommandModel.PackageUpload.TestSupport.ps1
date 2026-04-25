$global:novaCommandModelPackageUploadTestSupportFunctionNameList = @(
    'Get-TestNovaPackageUploadOptionValue'
    'Initialize-TestNovaPackageUploadLayout'
    'New-TestNovaPackageUploadProjectInfo'
    'New-TestNovaPackageArtifactFile'
    'New-TestNovaPackageArtifactSet'
    'Get-TestNovaPackageUploadConfirmActionCases'
    'Get-TestNovaPackageUploadSuspendWarningCount'
    'Get-TestNovaPackageUploadTargetResolutionCases'
    'Get-TestNovaPackageUploadRepositoryList'
    'Assert-TestNovaPackageUploadTargetResolutionResult'
    'Get-TestNovaPackageUploadHeaderResolutionCases'
    'Get-TestNovaPackageUploadArtifactResolutionCases'
    'Get-TestNovaPackageUploadFailureCases'
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

function Get-TestNovaPackageUploadConfirmActionCases {
    [CmdletBinding()]
    param()

    return @(
        @{Choice = 'Y'; Expected = $true; ExpectSuspendWarning = $false}
        @{Choice = 'A'; Expected = $true; ExpectSuspendWarning = $false}
        @{Choice = 'N'; Expected = $false; ExpectSuspendWarning = $false}
        @{Choice = 'L'; Expected = $false; ExpectSuspendWarning = $false}
        @{Choice = 'S'; Expected = $false; ExpectSuspendWarning = $true}
    )
}

function Get-TestNovaPackageUploadSuspendWarningCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$ExpectSuspendWarning
    )

    if ($ExpectSuspendWarning) {
        return 1
    }

    return 0
}

function Get-TestNovaPackageUploadTargetResolutionCases {
    [CmdletBinding()]
    param()

    return @(
        @{
            Name = 'repository settings should override package headers and auth'
            ProjectRootName = 'target-merge-precedence'
            UseExplicitOverride = $false
            ExpectedUrl = 'https://packages.example/raw/repository/'
            ExpectedUploadPath = 'repo-path'
            ExpectedTraceId = 'repo-trace'
            ExpectPackageToken = $true
        }
        @{
            Name = 'explicit Url and UploadPath should override configured locations'
            ProjectRootName = 'target-explicit-overrides'
            UseExplicitOverride = $true
            ExpectedUrl = 'https://override.example/upload/'
            ExpectedUploadPath = 'manual/path'
            ExpectedTraceId = $null
            ExpectPackageToken = $false
        }
    )
}

function Get-TestNovaPackageUploadRepositoryList {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$ExpectedTraceId
    )

    $traceHeaders = if ($null -ne $ExpectedTraceId) {
        [ordered]@{'X-Trace-Id' = 'repo-trace'}
    }
    else {
        [ordered]@{}
    }

    return @(
        [ordered]@{
            Name = 'LocalRaw'
            Url = 'https://packages.example/raw/repository/'
            UploadPath = 'repo-path'
            Headers = [ordered]@{} + $traceHeaders + [ordered]@{
                'X-Repo-Only' = 'repo-only'
            }
            Auth = [ordered]@{
                HeaderName = 'X-Repo-Token'
                TokenEnvironmentVariable = 'REPO_UPLOAD_TOKEN'
            }
        }
    )
}

function Assert-TestNovaPackageUploadTargetResolutionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [Parameter(Mandatory)][pscustomobject]$TestCase
    )

    $Result.Repository | Should -Be 'LocalRaw'
    $Result.Url | Should -Be $TestCase.ExpectedUrl
    $Result.UploadPath | Should -Be $TestCase.ExpectedUploadPath
    $Result.Headers['X-Package-Only'] | Should -Be 'package-only'
    $Result.Headers['X-Repo-Only'] | Should -Be 'repo-only'
    $Result.Auth.HeaderName | Should -Be 'X-Repo-Token'
    $Result.Auth.TokenEnvironmentVariable | Should -Be 'REPO_UPLOAD_TOKEN'

    if ($null -ne $TestCase.ExpectedTraceId) {
        $Result.Headers['X-Trace-Id'] | Should -Be $TestCase.ExpectedTraceId
    }

    if ($TestCase.ExpectPackageToken) {
        $Result.Auth.Token | Should -Be 'package-token'
    }
}

function Get-TestNovaPackageUploadHeaderResolutionCases {
    [CmdletBinding()]
    param()

    return @(
        Get-TestNovaPackageUploadHeaderResolutionNoTokenCase
        Get-TestNovaPackageUploadHeaderResolutionCustomHeaderCase
        Get-TestNovaPackageUploadHeaderResolutionAuthorizationCase
        Get-TestNovaPackageUploadHeaderResolutionOverrideCase
    )
}

function Get-TestNovaPackageUploadHeaderResolutionNoTokenCase {
    [CmdletBinding()]
    param()

    return New-TestNovaPackageUploadNamedHeaderResolutionCase -Name 'no token is available' -Token $null -ExpectedHeaders ([ordered]@{
        'X-Base' = 'base'
        'X-Override' = 'override'
    })
}

function Get-TestNovaPackageUploadHeaderResolutionCustomHeaderCase {
    [CmdletBinding()]
    param()

    return New-TestNovaPackageUploadNamedHeaderResolutionCase -Name 'a custom auth header should be added with the raw token' -Token 'secret-token' -ExpectedHeaders ([ordered]@{
        'X-Base' = 'base'
        'X-Override' = 'override'
        'X-Api-Key' = 'secret-token'
    })
}

function New-TestNovaPackageUploadNamedHeaderResolutionCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][string]$Token,
        [Parameter(Mandatory)][System.Collections.IDictionary]$ExpectedHeaders
    )

    return @{
        Name = $Name
        UploadTarget = [pscustomobject]@{
            Headers = [ordered]@{'X-Base' = 'base'}
            Auth = [ordered]@{
                HeaderName = 'X-Api-Key'
            }
        }
        UploadOption = [pscustomobject]@{
            Headers = [ordered]@{'X-Override' = 'override'}
            Token = $Token
            TokenEnvironmentVariable = $null
            AuthenticationScheme = $null
        }
        ExpectedHeaders = [ordered]@{} + $ExpectedHeaders
    }
}

function Get-TestNovaPackageUploadHeaderResolutionAuthorizationCase {
    [CmdletBinding()]
    param()

    return @{
        Name = 'Authorization should use the explicit authentication scheme'
        UploadTarget = [pscustomobject]@{
            Headers = [ordered]@{'X-Base' = 'base'}
            Auth = [ordered]@{}
        }
        UploadOption = [pscustomobject]@{
            Headers = [ordered]@{}
            Token = 'secret-token'
            TokenEnvironmentVariable = $null
            AuthenticationScheme = 'Basic'
        }
        ExpectedHeaders = [ordered]@{
            'X-Base' = 'base'
            'Authorization' = 'Basic secret-token'
        }
    }
}

function Get-TestNovaPackageUploadHeaderResolutionOverrideCase {
    [CmdletBinding()]
    param()

    return @{
        Name = 'the auth header should override an existing merged header with the same name'
        UploadTarget = [pscustomobject]@{
            Headers = [ordered]@{'Authorization' = 'stale-value'}
            Auth = [ordered]@{}
        }
        UploadOption = [pscustomobject]@{
            Headers = [ordered]@{'Authorization' = 'also-stale'}
            Token = 'fresh-token'
            TokenEnvironmentVariable = $null
            AuthenticationScheme = 'Bearer'
        }
        ExpectedHeaders = [ordered]@{
            'Authorization' = 'Bearer fresh-token'
        }
    }
}

function Get-TestNovaPackageUploadArtifactResolutionCases {
    [CmdletBinding()]
    param()

    return @(
        @{
            Name = 'multiple artifacts exist for the configured package types'
            ProjectRootName = 'multi-artifact-upload'
            Options = @{PackageTypes = @('Zip', 'NuGet')}
            ExpectedPackagePathFilter = 'PackageProject.*'
            ExpectedTypeList = @('NuGet', 'NuGet', 'Zip', 'Zip')
        }
        @{
            Name = 'FileNamePattern targets zip artifacts'
            ProjectRootName = 'explicit-zip-pattern-upload'
            Options = @{PackageTypes = @('Zip', 'NuGet'); FileNamePattern = 'PackageProject.*.zip'}
            ExpectedPackagePathFilter = '*.zip'
            ExpectedTypeList = @('Zip', 'Zip')
        }
    )
}

function Get-TestNovaPackageUploadFailureCases {
    [CmdletBinding()]
    param()

    return @(
        @{
            Name = 'the upload target URL is missing'
            ProjectRootName = 'missing-upload-url'
            ExpectedError = [pscustomobject]@{
                Message = 'Upload target URL is missing*'
                ErrorId = 'Nova.Configuration.PackageUploadTargetUrlMissing'
                Category = [System.Management.Automation.ErrorCategory]::InvalidData
                TargetObject = 'Url'
            }
            Invoke = {
                param($PackagePath)

                Deploy-NovaPackage -PackagePath $PackagePath
            }
        }
        @{
            Name = 'package selection is ambiguous'
            ProjectRootName = 'ambiguous-package-selection'
            ExpectedError = [pscustomobject]@{
                Message = 'Package selection is ambiguous*'
                ErrorId = 'Nova.Validation.PackageUploadSelectionAmbiguous'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
            }
            Invoke = {
                param($PackagePath)

                Deploy-NovaPackage -PackagePath $PackagePath -PackageType NuGet -Url 'https://packages.example/raw/'
            }
        }
    )
}

