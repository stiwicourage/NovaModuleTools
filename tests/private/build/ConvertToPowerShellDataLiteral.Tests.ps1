BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/ConvertToPowerShellDataLiteral.ps1')
}

Describe 'ConvertTo-PowerShellDataLiteral' {
    It 'serializes an empty string' {
        ConvertTo-PowerShellDataLiteral -Value '' | Should -Be "''"
    }

    It 'serializes a string with apostrophes safely' {
        ConvertTo-PowerShellDataLiteral -Value "don't run" | Should -Be "'don''t run'"
    }

    It 'quotes arbitrary dictionary keys safely' {
        $value = [ordered]@{
            'Example Product' = $true
            'Example-Product' = 3
            "Owner's Choice" = 'ready'
            '123abc' = $null
        }

        $result = ConvertTo-PowerShellDataLiteral -Value $value

        $result.Contains('''Example Product'' = $true') | Should -BeTrue
        $result.Contains('''Example-Product'' = 3') | Should -BeTrue
        $result.Contains('''Owner''''s Choice'' = ''ready''') | Should -BeTrue
        $result.Contains('''123abc'' = $null') | Should -BeTrue
    }

    It 'serializes boolean true' {
        ConvertTo-PowerShellDataLiteral -Value $true | Should -Be '$true'
    }

    It 'serializes boolean false' {
        ConvertTo-PowerShellDataLiteral -Value $false | Should -Be '$false'
    }

    It 'serializes null' {
        ConvertTo-PowerShellDataLiteral -Value $null | Should -Be '$null'
    }

    It 'serializes integers' {
        ConvertTo-PowerShellDataLiteral -Value 3 | Should -Be '3'
    }

    It 'serializes numbers' {
        ConvertTo-PowerShellDataLiteral -Value 3.5 | Should -Be '3.5'
    }

    It 'serializes unsupported scalar values as quoted strings' {
        $version = [version]'1.2.3'

        ConvertTo-PowerShellDataLiteral -Value $version | Should -Be "'1.2.3'"
    }

    It 'serializes empty objects' {
        ConvertTo-PowerShellDataLiteral -Value ([ordered]@{}) | Should -Be '@{}'
    }

    It 'serializes nested objects and arrays recursively' {
        $value = [ordered]@{
            ExampleProduct = [ordered]@{
                Enabled = $true
                ApiVersion = '1'
                RetryCount = 3
                Nested = [ordered]@{
                    Mode = 'Test'
                }
                Values = @('one', 'two')
            }
        }

        $result = ConvertTo-PowerShellDataLiteral -Value $value

        $result.Contains("`n    'ExampleProduct' = @{") | Should -BeTrue
        $result.Contains('''Enabled'' = $true') | Should -BeTrue
        $result.Contains('''ApiVersion'' = ''1''') | Should -BeTrue
        $result.Contains('''RetryCount'' = 3') | Should -BeTrue
        $result.Contains('''Nested'' = @{') | Should -BeTrue
        $result.Contains('''Mode'' = ''Test''') | Should -BeTrue
        $result.Contains('''Values'' = @(') | Should -BeTrue
        $result.Contains('''one''') | Should -BeTrue
        $result.Contains('''two''') | Should -BeTrue
    }

    It 'sorts plain hashtable keys deterministically' {
        $value = @{b = 2; a = 1}

        $result = ConvertTo-PowerShellDataLiteral -Value $value

        $result.IndexOf("'a' = 1") | Should -BeLessThan $result.IndexOf("'b' = 2")
    }

    It 'preserves ordered dictionary keys in their configured order' {
        $value = [ordered]@{
            b = 2
            a = 1
        }

        $result = ConvertTo-PowerShellDataLiteral -Value $value

        $result.IndexOf("'b' = 2") | Should -BeLessThan $result.IndexOf("'a' = 1")
    }

    It 'throws for unsupported collection values' {
        $queue = [System.Collections.Queue]::new()

        { Get-PowerShellCollectionBlockDescriptor -Value $queue } | Should -Throw 'Unsupported PowerShell data collection type*'
    }
}
