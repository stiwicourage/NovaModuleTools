BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/WriteNovaPackageUploadResultOutput.ps1')
}

Describe 'Write-NovaPackageUploadResultOutput' {
    BeforeEach {
        Mock Write-Host {}
    }

    It 'writes a single-artifact summary and URL-specific next step' {
        $result = @([pscustomobject]@{UploadUrl = 'https://packages.example/raw/NovaModuleTools.1.0.0.nupkg'})

        Write-NovaPackageUploadResultOutput -Result $result

        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Uploaded 1 package artifact.'}
        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Next step: verify the uploaded artifact at https://packages.example/raw/NovaModuleTools.1.0.0.nupkg.'}
    }

    It 'writes a multi-artifact summary and repository-level next step' {
        $result = @(
            [pscustomobject]@{UploadUrl = 'https://packages.example/raw/a.nupkg'}
            [pscustomobject]@{UploadUrl = 'https://packages.example/raw/b.nupkg'}
        )

        Write-NovaPackageUploadResultOutput -Result $result

        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Uploaded 2 package artifacts.'}
        Should -Invoke Write-Host -Times 1 -ParameterFilter {$Object -eq 'Next step: verify the uploaded artifacts at the target repository.'}
    }
}
