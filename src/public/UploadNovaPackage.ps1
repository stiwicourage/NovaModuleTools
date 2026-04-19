function Upload-NovaPackage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Upload is the intentional public command name for raw package delivery in the Nova command model.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string[]]$PackagePath,
        [string[]]$PackageType,
        [string]$Url,
        [string]$Repository
    )

    dynamicparam {
        return New-NovaPackageUploadDynamicParameterDictionary
    }

    end {
        $projectInfo = Get-NovaProjectInfo
        $uploadOption = New-NovaPackageUploadOption -BoundParameters $PSBoundParameters
        $uploadArtifactList = @(Resolve-NovaPackageUploadInvocation -ProjectInfo $projectInfo -UploadOption $uploadOption)
        $uploadResultList = @()

        foreach ($uploadArtifact in $uploadArtifactList) {
            $uploadAction = "Upload $( $uploadArtifact.Type ) package artifact $( $uploadArtifact.PackageFileName )"
            if (-not $PSCmdlet.ShouldProcess($uploadArtifact.UploadUrl, $uploadAction)) {
                continue
            }

            $uploadResultList += Invoke-NovaPackageArtifactUpload -UploadArtifact $uploadArtifact
        }

        return $uploadResultList
    }
}
