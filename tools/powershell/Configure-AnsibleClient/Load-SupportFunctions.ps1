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
