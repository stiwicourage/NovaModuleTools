BeforeAll {
    $script:projectRoot = Split-Path -Parent $PSScriptRoot
    $script:moduleName = 'NovaModuleTools'
    $script:moduleManifestPath = Join-Path $script:projectRoot 'dist/NovaModuleTools/NovaModuleTools.psd1'
    $publicDir = Join-Path $script:projectRoot 'src/public'

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:moduleManifestPath -Force -ErrorAction Stop

    $script:expectedCommandName = @(
        foreach ($file in (Get-ChildItem -LiteralPath $publicDir -Filter '*.ps1' -File | Sort-Object -Property Name)) {
            $null = $token = $parseError = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$token, [ref]$parseError)
            $definition = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $false)

            foreach ($item in $definition) {
                $item.Name
            }
        }
    ) | Sort-Object
    $script:exportedCommandName = @(
        Get-Command -Module $script:moduleName -CommandType Function |
            Select-Object -ExpandProperty Name |
            Sort-Object
    )
}

Describe 'Build validation smoke integration' {
    It 'imports the built module without error' {
        (Get-Module -Name $script:moduleName) | Should -Not -BeNullOrEmpty
    }

    It 'exports every public command from src/public' {
        $script:exportedCommandName | Should -Be $script:expectedCommandName
    }
}
