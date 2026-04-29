function Initialize-PSGalleryRepository {
    [CmdletBinding()]
    param()

    $storeDirectory = Get-PSResourceRepositoryStoreDirectory
    if (-not (Test-Path -LiteralPath $storeDirectory)) {
        New-Item -ItemType Directory -Path $storeDirectory -Force | Out-Null
    }

    if ($null -eq (Get-PSResourceRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Register-PSResourceRepository -PSGallery
    }
}

