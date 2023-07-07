[CmdletBinding()]
param ()

# This is kind of ugly, but we can use `Start-Process -Credentail` to login as
# $ClatUser to create their profile. We need the profile path, but Start-Process
# does not return STDOUT to process so we will redirect the contents of
# USERPROFILE to a file that we can later read

[scriptblock]$ScriptBlock = {
    $TaskName = "Creating profile for $ClatUser"
    Write-Verbose $TaskName
    try {
        $null = Start-Process cmd -ArgumentList "/C echo %USERPROFILE%" -Credential $ClatCredential -Wait -LoadUserProfile -UseNewEnvironment
    } catch {
        throw "$($TaskName): $_"
    }

    $TaskName = "Getting profile path for $ClatUser"
    Write-Verbose $TaskName
    try {
        $Sid = (Get-LocalUser $ClatUser).SID.Value
        $Global:ProfilePath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid").ProfileImagePath
    } catch {
        throw "$($TaskName): $_"
    }

}

Call-Script -Objective "Create profile for clat-ansible user" -Script $ScriptBlock
