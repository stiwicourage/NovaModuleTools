function New-TestPromptHostUi {
    param([Parameter(Mandatory)][scriptblock]$GetResponse)

    $hostUi = [pscustomobject]@{
        State = [ordered]@{
            PromptCalls = 0
            GetResponse = $GetResponse
        }
    }
    $hostUi | Add-Member -MemberType ScriptMethod -Name Prompt -Value {
        $this.State.PromptCalls += 1
        return & $this.State.GetResponse $this.State.PromptCalls
    }

    return $hostUi
}

function New-TestChoiceHostUi {
    param([int]$ChoiceIndex = 0)

    $hostUi = [pscustomobject]@{
        State = [ordered]@{
            ChoiceCalls = 0
            ChoiceLabels = @()
            DefaultChoiceIndex = $null
            ChoiceIndex = $ChoiceIndex
        }
    }
    $hostUi | Add-Member -MemberType ScriptMethod -Name PromptForChoice -Value {
        $this.State.ChoiceCalls += 1
        $this.State.ChoiceLabels = @($args[2] | ForEach-Object Label)
        $this.State.DefaultChoiceIndex = $args[3]
        return $this.State.ChoiceIndex
    }

    return $hostUi
}



