[CmdletBinding()]
param ()

# Describe what you're trying to do (imperative). The obejective should fit into
# the following sentence: "Attmpting to do $Objective"

# Examples
# - Install Chocolatey package manager
# - Configure OpenSSH server

[scriptblock]$ScriptBlock = {
    $TaskName = "<Name for this task (there could be many)>"
    Write-Verbose $TaskName
    try {
        "<Do something here>"
    } catch {
        throw "$($TaskName): $_"
    }

}

Call-Script -Objective "<Replace this with the real objective>" -Script $ScriptBlock
