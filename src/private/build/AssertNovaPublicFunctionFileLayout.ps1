function Get-NovaPublicFunctionFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    return @(Get-ChildItem -Path $ProjectInfo.PublicDir -Filter *.ps1 -File -ErrorAction SilentlyContinue)
}

function Get-NovaInvalidPublicFunctionFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $invalidFileList = foreach ($publicFunctionFile in (Get-NovaPublicFunctionFileList -ProjectInfo $ProjectInfo)) {
        $functionNameList = @(Get-FunctionNameFromFile -filePath $publicFunctionFile.FullName)
        if ($functionNameList.Count -eq 1) {
            continue
        }

        [pscustomobject]@{
            FilePath = if ($ProjectInfo.PSObject.Properties.Name -contains 'ProjectRoot') {
                [System.IO.Path]::GetRelativePath($ProjectInfo.ProjectRoot, $publicFunctionFile.FullName)
            } else {
                $publicFunctionFile.FullName
            }
            FunctionNameList = $functionNameList
        }
    }

    return @($invalidFileList)
}

function Format-NovaPublicFunctionFileValidationMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$InvalidFileList
    )

    $messageLines = @(
        'Files under src/public must contain exactly one top-level function to avoid accidental public API leaks.'
        ''
        'Invalid files:'
    )

    foreach ($invalidFile in $InvalidFileList) {
        $functionText = if (@($invalidFile.FunctionNameList).Count -eq 0) {
            '<none>'
        } else {
            @($invalidFile.FunctionNameList) -join ', '
        }

        $messageLines += "- $( $invalidFile.FilePath ): $functionText"
    }

    $messageLines += @(
        ''
        'Affected commands: Invoke-NovaBuild, nova build, Test-NovaBuild -Build, nova test --build/-b, New-NovaModulePackage, nova package (--skip-tests/-s), Publish-NovaModule, nova publish (--skip-tests), Invoke-NovaRelease, nova release (--skip-tests/-s).'
        'Fix the file layout or continue intentionally with -OverrideWarning / --override-warning / -o.'
    )

    return $messageLines -join [Environment]::NewLine
}

function Assert-NovaPublicFunctionFileLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [switch]$OverrideWarningRequested
    )

    $invalidFileList = @(Get-NovaInvalidPublicFunctionFileList -ProjectInfo $ProjectInfo)
    if ($invalidFileList.Count -eq 0) {
        return
    }

    $message = Format-NovaPublicFunctionFileValidationMessage -InvalidFileList $invalidFileList
    Write-Warning $message

    if ($OverrideWarningRequested) {
        Write-Verbose 'Continuing build because OverrideWarning was specified.'
        return
    }

    Stop-NovaOperation -Message $message -ErrorId 'Nova.Validation.PublicFunctionFileLayoutInvalid' -Category InvalidData -TargetObject $ProjectInfo.PublicDir
}
