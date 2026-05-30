BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/TestProjectSchema.ps1')

    . (Join-Path $PSScriptRoot 'TestProjectSchema.TestSupport.ps1')
}

Describe 'Test-ProjectSchema' {
    BeforeEach {
        $script:tempSchema = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.json')
        Set-Content -LiteralPath $script:tempSchema -Value '{}'
        Mock Get-ResourceFilePath {return $script:tempSchema}
        Mock Test-Json {return $true}
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempSchema -ErrorAction SilentlyContinue
    }

    It 'validates project.json against Schema-Project.json and returns true' {
        Test-ProjectSchema | Should -BeTrue
        Assert-MockCalled Get-ResourceFilePath -Times 1 -ParameterFilter {$FileName -eq 'Schema-Project.json'}
    }

    It 'translates Test-Json failures into Stop-NovaOperation' {
        Mock Test-Json {throw 'bad schema'}

        {Test-ProjectSchema} | Should -Throw
    }
}
