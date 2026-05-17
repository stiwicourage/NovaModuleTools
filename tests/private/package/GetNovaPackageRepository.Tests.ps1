BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageRepository.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Get-NovaPackageSettingValue {param($InputObject, $Name)
        if ($null -eq $InputObject) {return $null}
        if ($InputObject -is [System.Collections.IDictionary]) {return $InputObject[$Name]}
        return $InputObject.$Name
    }
}

Describe 'Get-NovaPackageRepository' {
    It 'returns $null when Repository is empty' {
        Get-NovaPackageRepository -ProjectInfo ([pscustomobject]@{Package=$null}) -Repository '' | Should -BeNullOrEmpty
    }

    It 'returns the matching repository case-insensitively' {
        $repo = [pscustomobject]@{Name='Nexus'; Url='https://x'}
        $project = [pscustomobject]@{Package=[pscustomobject]@{Repositories=@($repo)}}
        Get-NovaPackageRepository -ProjectInfo $project -Repository 'nexus' | Should -Be $repo
    }

    It 'stops when the repository name is not configured' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{Repositories=@()}}
        {Get-NovaPackageRepository -ProjectInfo $project -Repository 'Nexus'} | Should -Throw '*Package repository not found*'
    }
}
