[CmdletBinding()]
param ()

[scriptblock]$ScriptBlock = {
    $TaskName = "Create clat-ansible user and add to Local Administrators"
    Write-Verbose $TaskName
    try {
        if(-NOT (Get-LocalUser $ClatUser -ErrorAction SilentlyContinue)){
            $TaskName = "Create user $($ClatUser)"
            Write-Verbose $TaskName
            try {
                $null = New-LocalUser -Name $ClatUser -Password $ClatssPassword -FullName "CLAT Ansible" -Description "CLAT Ansible user" -PasswordNeverExpires -UserMayNotChangePassword -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }
    
            $TaskName = "Add $($ClatUser) to the local Administrators group"
            Write-Verbose $TaskName
            try {
                $null = Add-LocalGroupMember -Group "Administrators" -Member $ClatUser -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }
    
        } else {
            # We need to set the password to the current password to continue working
            $TaskName = "Change password for $($ClatUser)"
            Write-Verbose $TaskName
            try {
                Get-LocalUser $ClatUser -ErrorAction Stop | Set-LocalUser -Password $ClatssPassword -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }
    
        }
    
    } catch {
        throw "$($TaskName): $_"
    }

}

Call-Script -Objective "Create $($ClatUser) local user and add it to the Administrators group" -Script $ScriptBlock
