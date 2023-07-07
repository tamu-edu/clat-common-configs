[CmdletBinding()]
param ()

[scriptblock]$ScriptBlock = {

    $DotSshFolder = "$($Global:ProfilePath)\.ssh"
    $AuthorizedKeyFile = "$($DotSshFolder)\authorized_keys"

    # if (Test-Path $DotSshFolder -ErrorAction SilentlyContinue){
    #     $TaskName = "Set permissions for current user on $DotSshFolder"
    #     Write-Verbose $TaskName
    #     try {
    #         Set-Permissions -User "$(whoami)" -Path $DotSshFolder -AccessRights FullControl -RemovePrevious
    #     } catch {
    #         throw "$($TaskName): $_"
    #     }

    #     $TaskName = "Removing existing $DotSshFolder"
    #     Write-Verbose $TaskName
    #     try {
    #         if (Test-Path $AuthorizedKeyFile -ErrorAction SilentlyContinue) {
    #             Set-Permissions -User "$(whoami)" -Path $AuthorizedKeyFile  -AccessRights FullControl
    #         }
    #         $null = Remove-Item $AuthorizedKeyFile -Force -ErrorAction Stop
    #         $null = Remove-Item $DotSshFolder -Recurse -Force -ErrorAction Stop
    #     } catch {
    #         throw "$($TaskName): $_"
    #     }

    # }

    $TaskName = "Create the .ssh folder as $($Global:ClatUser)"
    Write-Verbose $TaskName
    try {
        $null = mkdir $ProfilePath\.ssh -ErrorAction Stop
    } catch {
        throw "$($TaskName): $_"
    }

    $TaskName = "Create the authorized_keys file in $($Global:ClatUser)\.ssh"
    Write-Verbose $TaskName
    try {
        Set-Content $AuthorizedKeyFile -Value $PublicKey
    } catch {
        throw "$($TaskName): $_"
    }

    # Adapted from https://stackoverflow.com/a/43317244

    $TaskName = "Set the correct permissions on $AuthorizedKeyFile"
    Write-Verbose $TaskName
    try {
        $TaskName = "Set ReadExecute permissions for owner and System on $DotSshFolder"
        Write-Verbose $TaskName
        try {
            Set-Permissions -User $Global:ClatUser -Path $AuthorizedKeyFile -AccessRights FullControl -RemovePrevious
            Set-Permissions -User "NT AUTHORITY\SYSTEM" -Path $AuthorizedKeyFile -AccessRights FullControl -RemovePrevious
            
        } catch {
            throw "$($TaskName): $_"
        }
    } catch {
        throw "$($TaskName): $_"
    }
  
}

Call-Script -Objective "Create the authorized_keys file in the .ssh folder of the profile" -Script $ScriptBlock
"done"