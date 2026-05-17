BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Invoke-NovaModuleUpdateNotificationSafely' {
    It 'swallows update lookup failures' {
        InModuleScope $script:moduleName {
            Mock Invoke-NovaModuleUpdateNotification {throw 'network issue'}

            {Invoke-NovaModuleUpdateNotificationSafely} | Should -Not -Throw
            Assert-MockCalled Invoke-NovaModuleUpdateNotification -Times 1
        }
    }
}

