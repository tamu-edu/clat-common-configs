[CmdletBinding()]
param ()

[scriptblock]$ScriptBlock = {
    try {
        $Global:ClatPassword = ([guid]::NewGuid()).Guid
        $Global:ClatssPassword = ConvertTo-SecureString -AsPlainText $ClatPassword -Force -ErrorAction Stop
        $Global:ClatCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClatUser, $ClatssPassword -ErrorAction Stop
    } catch {
        throw "Encountered the following error creating the credential for $($ClatUser): $_"
    }
}

Call-Script -Objective "Build credential object for $($ClatUser)" -Script $ScriptBlock
