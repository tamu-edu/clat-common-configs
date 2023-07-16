function Call-Script {
    [CmdletBinding()] param (
        [scriptblock] $ScriptBlock
       ,[string] $Objective
    )

    Write-Verbose "$($Objective): starting"

    $ErrorTemplate = "$($Objective): Encountered an error {0}"
    try {
        Invoke-Command -ScriptBlock $ScriptBlock
    } catch {
        throw
    }

    Write-Verbose "$($Objective): completed successfully`n-------------------------------------------------------------------------------"
}

function Get-ScriptOrder {
    [CmdletBinding()] param ()
    
    $Objective = 'Get script order'
    
    [scriptblock]$ScriptBlock = {
        try {
            $Global:ScriptOrder = Get-Content $Global:ProjectPath\Order.txt | Where-Object {$_}
        } catch {
            throw
        }
    }
    
    Call-Script -Objective $Objective -Script $ScriptBlock
                
}

function Set-Permissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][ValidateSet('ReadAndExecute', 'FullControl')][string]$AccessRights,
        [Parameter(Mandatory=$false)][switch]$RemovePrevious,
        [Parameter(Mandatory=$false)][switch]$Inherit

    )

    $InheritanceFlags = "None"
    $PropagationFlag = "None"

    $AccessControlList = Get-Acl -Path $Path -ErrorAction Stop
    $AccessControlList.SetAccessRuleProtection($false, $true)

    if ([System.IO.Directory]::Exists($Path) -and $Inherit) {
        $AccessControlList.SetAccessRuleProtection($true, $false)
        $InheritanceFlags = "ContainerInherit, ObjectInherit" 
        $PropagationFlag = "InheritOnly"
    }
    
    if ($RemovePrevious){
        $null = $AccessControlList.Access | ForEach-Object { $AccessControlList.RemoveAccessRule($_) }
    }

    $Permissions = $User, $AccessRights, $InheritanceFlags, $PropagationFlag, "Allow"
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Permissions)
    $AccessControlList.AddAccessRule($AccessRule)

    Set-Acl -Path $Path -ACL $AccessControlList -ErrorAction Stop
}


function Set-SshHostKeyFilePerms {
    [CmdletBinding()] param (
        [switch] $RemovePermissions
    )
    $SshdFolder = (Resolve-Path "C:\ProgramData\ssh\").Path
    try {
        if(-NOT $RemovePermissions){
            Write-Verbose "Applying correct permissions on c:\ProgramData\ssh\ssh_host* files"
            try {
                $null = Get-ChildItem -Path "$($SshdFolder)ssh_host_*_key" -ErrorAction Stop | ForEach-Object {  
                    Write-Verbose "Setting permissions full control on $($_.FullName) to 'nt authority\system'"
                    $acl = Get-Acl $_.FullName

                    Write-Verbose "Disable inheritance and apply"
                    $acl.SetAccessRuleProtection($true,$true)
                    $acl | Set-Acl -Path $_.FullName

                    # 
                    Write-Verbose "Remove existing rules"
                    $rules = $acl.Access
                    foreach($rule in $rules) {
                        $acl.RemoveAccessRule($rule)
                    }

                    Write-Verbose "Create a new rule for just 'nt authority\system' on $($_.FullName)"
                    $ar = New-Object  System.Security.AccessControl.FileSystemAccessRule("nt authority\system", "FullControl", "Allow")
                    $acl.SetAccessRule($ar)

                    Write-Verbose "Apply new rules to $($_.FullName)"
                    $null = Set-Acl $_.FullName $acl -ErrorAction Stop
                }
            } catch {
                throw "$($TaskName): $_"
            }

        } else {
            Write-Verbose "Resetting permissions to allow Admin access to c:\ProgramData\ssh\ssh_host* files"
            $MyUser = whoami

            Write-Verbose "Taking ownership of $($_.FullName)"
            $Output = takeown.exe /f $SshdFolder /a /r /d Y
            if ($LASTEXITCODE){
                throw $Output
            }

            $null = Get-ChildItem -Path "$($SshdFolder)ssh_host_*_key" -ErrorAction Stop | ForEach-Object {    
                Write-Verbose "Grant $MyUser full control on $($_.FullName)"
                $Output = icacls $_.FullName /grant "$($MyUser):(F)"
                if ($LASTEXITCODE){
                    throw $Output
                }

                # Remove-Item $_.FullName -Force -ErrorAction Stop
            }
        }
    } catch {
        throw
    }
}