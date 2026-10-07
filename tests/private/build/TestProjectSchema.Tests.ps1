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

    It 'accepts project.json when Manifest.PrivateData is omitted' {
        $schemaPath = Join-Path $projectRoot 'src/resources/Schema-Project.json'
        $projectJsonPath = Join-Path $TestDrive 'project-no-private-data.json'
        Set-Content -LiteralPath $projectJsonPath -Value @'
{
  "ProjectName": "Demo",
  "Description": "Demo module",
  "Version": "1.0.0",
  "Manifest": {
    "Author": "Nova",
    "PowerShellHostVersion": "7.4",
    "GUID": "11111111-1111-1111-1111-111111111111"
  }
}
'@

        Test-Json -Path $projectJsonPath -Schema (Get-Content -LiteralPath $schemaPath -Raw) | Should -BeTrue
    }

    It 'accepts project.json when Manifest.PrivateData contains arbitrary nested data' {
        $schemaPath = Join-Path $projectRoot 'src/resources/Schema-Project.json'
        $projectJsonPath = Join-Path $TestDrive 'project-private-data.json'
        Set-Content -LiteralPath $projectJsonPath -Value @'
{
  "ProjectName": "Demo",
  "Description": "Demo module",
  "Version": "1.0.0",
  "Manifest": {
    "Author": "Nova",
    "PowerShellHostVersion": "7.4",
    "GUID": "11111111-1111-1111-1111-111111111111",
    "PrivateData": {
      "ExampleProduct": {
        "Enabled": true,
        "ApiVersion": "1",
        "RetryCount": 3,
        "Nested": {
          "Mode": "Test"
        },
        "Values": [
          "one",
          "two"
        ],
        "Nothing": null,
        "EmptyObject": {}
      }
    }
  }
}
'@

        Test-Json -Path $projectJsonPath -Schema (Get-Content -LiteralPath $schemaPath -Raw) | Should -BeTrue
    }
}
