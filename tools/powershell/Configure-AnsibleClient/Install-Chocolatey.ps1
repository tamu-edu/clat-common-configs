[CmdletBinding()]
param ()

[scriptblock]$ScriptBlock = {
    $TaskName = "Install Chocolatey"
    Write-Verbose $TaskName
    try {
        if(-NOT (where.exe choco.exe)){
            # Excerpt from Chocolatey install site
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    } catch {
        throw "$($TaskName): $_"
    }
}

Call-Script -Objective 'Install Chocolatey package manager' -Script $ScriptBlock
