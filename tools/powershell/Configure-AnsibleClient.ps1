[CmdletBinding()] param (
    [string] $ClatUser = 'clat-ansible',
    [string] $PublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH2tQuHdBAnr+hKo0+I05fLr9Vo0un2PFQkjAnkPMIW',
    [string] $SshConfigurationLocation = '\\CLAT-FS01.artsci.tamu.edu\CLAT-Windows-Admin\Server Configuration\files\sshd_config',
    [string] $LocalSshFolder = 'C:\ProgramData\ssh\',
    [string[]] $ExcludePackages,
    [switch] $ForceChocoSshInstall
)

begin {

    # The script is intended for PowerShell 5.1 or higher.
    $Global:PsVersion = $PSVersionTable.PSVersion | Select-Object Major, Minor

    if (-NOT (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
        throw 'This operation requires elevation. Start PowerShell with "run as Administrator"'
    }

    try {
        $Global:ProjectPath = "$((Resolve-Path $PSScriptRoot).Path)\Configure-AnsibleClient"
    } catch {
        "Encountered an error trying to get the Project Path from $($PSScriptRoot)"
    }

    $TempFolder = $env:TEMP
    Write-Verbose "Temp folder: $TempFolder"

    # Start by calling Get-ScriptOrder.ps1 to set the script order
    $TaskName = "Loading support function(s)"
    Write-Verbose $TaskName
    try {
        . $ProjectPath\Load-SupportFunctions.ps1
    } catch {
        throw "$($TaskName): $_"
    }

    $TaskName = "Getting script order"
    Write-Verbose $TaskName
    try {
        $Global:ScriptOrder = "-"
        Get-ScriptOrder
    } catch {
        throw "$($TaskName): $_"
    }

    $Global:ClatPassword   = [string]$null
    $Global:ClatssPassword = [string]$null
    $Global:ClatCredential = [pscustomobject]$null
}

process {
    Write-Verbose "Starting install and configuration tasks"
    foreach ($Script in ($Global:ScriptOrder | Where-Object {$_ -notin $ExcludePackages})){
        $ScriptFile = "$($Global:ProjectPath)\$($Script).ps1"
        . $ScriptFile
    }
}