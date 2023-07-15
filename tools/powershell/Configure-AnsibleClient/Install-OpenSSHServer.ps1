[CmdletBinding()]
param ()

[scriptblock]$ScriptBlock = {
    # Need to ensure that we can find the PowerShell 
    # Exe to set the shell for SSH before doing an
    # uninstall/install
    if ($Global:PsVersion.Major -eq 5) {
        $PsExe = 'powershell.exe'
    } else {
        $PsExe = 'pwsh.exe'
    }

    $PsPath = (where.exe $PsExe)
    if (-NOT $PsPath){
        throw "Was unable to locate $PsExe for $($PsVersionTable.PSVersion.ToString())"
    }

    # Install OpenSSH using Chocolatey if the OpenSSH.Server capability is not available
    if (([System.Environment]::OSVersion.Version).Major -le 6){
        $InstallWindowsCapability = $false
    } else {
        $InstallWindowsCapability = $true
    }

    if ((-NOT $InstallWindowsCapability) -or $Global:ForceChocoSshInstall){
        $TaskName = "Installing/reinstalling OpenSSH in Windows 2012 or older"
        Write-Verbose $TaskName
        try {
            if (choco list -lo | Select-String openssh){
                $TaskName = "Removing previous version of OpenSSH"
                Write-Verbose $TaskName
                try {
                    $ChocoOutput = choco uninstall openssh --y -force -params '"/SSHServerFeature /DeleteConfigAndServerKeys"'
                    if ($LASTEXITCODE -ne 0){
                        throw $ChocoOutput
                    }
                    $RefreshEnvOutput = . RefreshEnv.cmd
                    if ($LASTEXITCODE -ne 0){
                        throw $RefreshEnvOutput
                    }
                } catch {
                    throw "$($TaskName): $_"
                }
            }
            
            $TaskName = "Installing OpenSSH with Chocolatey"
            Write-Verbose $TaskName
            $TaskName = ""
            Write-Verbose $TaskName
            try {
                $ChocoOutput = choco install OpenSSH --y -force -params '"/SSHServerFeature /DeleteConfigAndServerKeys"'
                if ($LASTEXITCODE -ne 0){
                    throw $ChocoOutput
                }
            } catch {
                throw "$($TaskName): $_"
            }

            $TaskName = "Running install-sshd.ps1 to configure SSH"
            Write-Verbose $TaskName
            try {
                $null = . "C:\Program Files\OpenSSH-Win64\install-sshd.ps1" -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }


            $TaskName = "Generating host SSH keys"
            Write-Verbose $TaskName
            try {
                $KeygenOutput = . "C:\Program Files\OpenSSH-Win64\ssh-keygen.exe" -A
                if ($LASTEXITCODE){
                    throw $KeygenOutput
                }
            } catch {
                throw "$($TaskName): $_"
            }

            $TaskName = "Setting permissions on host SSH key files"
            Write-Verbose $TaskName
            try {
                $null = Get-ChildItem -Path 'C:\ProgramData\ssh\ssh_host_*_key' -ErrorAction Stop | ForEach-Object {    
                    $acl = get-acl $_.FullName
                    $ar = New-Object  System.Security.AccessControl.FileSystemAccessRule("NT Service\sshd", "Read", "Allow")
                    $acl.SetAccessRule($ar)
                    $null = Set-Acl $_.FullName $acl -ErrorAction Stop
                }
            } catch {
                throw "$($TaskName): $_"
            }
        
            $TaskName = "Opening ports for SSH in the firewall"
            Write-Verbose $TaskName
            try {
                $null = New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }

            
            $TaskName = "Setting sshd and ssh-agent to start automatically"
            Write-Verbose $TaskName
            try {
                $null = Set-Service SSHD -StartupType Automatic -ErrorAction Stop
                $null = Set-Service SSH-Agent -StartupType Automatic -ErrorAction Stop
            } catch {
                throw "$($TaskName): $_"
            }

        } catch {
            throw "installing OpenSSH using Chocolatey: $_"
        }
    } else {
        try {
            # Using Chocolatey to install the SSHServerFeature for consistency
            # instead of Add-WindowsCapability
            $TaskName = "Installing/reinstalling OpenSSH in Windows 2016 or greater"
            Write-Verbose $TaskName
            if ((Get-WindowsCapability -Online | where Name -like '*ssh*server*')){
                $TaskName = "Removing previous version of OpenSSH using Windows Capability"
                Write-Verbose $TaskName
                $null = Stop-Service sshd -ErrorAction SilentlyContinue
                $null = Remove-WindowsCapability -Name 'OpenSSH.Client~~~~0.0.1.0' -Online -ErrorAction Stop
                $null = Remove-WindowsCapability -Name 'OpenSSH.Server~~~~0.0.1.0' -Online -ErrorAction Stop
                $null = Remove-Item C:\ProgramData\ssh -Recurse -Force -ErrorAction SilentlyContinue
            } elseif (choco list -lo | Select-String openssh){
                $TaskName = "Removing previous version of OpenSSH with Chocolatey"
                Write-Verbose $TaskName
                try {
                    $ChocoOutput = choco uninstall openssh --y -force -params '"/SSHServerFeature /DeleteConfigAndServerKeys"'
                    if ($LASTEXITCODE -ne 0){
                        throw $ChocoOutput
                    }
                    $RefreshEnvOutput = . RefreshEnv.cmd
                    if ($LASTEXITCODE -ne 0){
                        throw $RefreshEnvOutput
                    }
                } catch {
                    throw "$($TaskName): $_"
                }
            } 

            $TaskName = "Installing OpenSSH with Chocolatey"
            Write-Verbose $TaskName
            try {
                $ChocoOutput = choco install OpenSSH --y -force -params '/SSHServerFeature'
                if ($LASTEXITCODE -ne 0){
                    throw $ChocoOutput
                }
            } catch {
                throw "$($TaskName): $_"
            }

            # Set the shell registry key for OpenSSH to point to PowerShell (
            # default is CMD)
            try {
                $RegistryPath = "HKLM:\SOFTWARE\OpenSSH"
                $RegistryKey = 'DefaultShell'
                $Value = $PsPath
                if (-NOT (Get-ItemProperty -Path $RegistryPath -Name $RegistryKey -ErrorAction SilentlyContinue)){
                    $null = New-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $Value -ErrorAction Stop
                } else {
                    $null = Set-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $Value -ErrorAction Stop
                }
            }
            catch {
                throw "Trying to set the shell registry value to: $PsExe"
            }

        } catch {
            throw "$($TaskName): $_"
        }

    }

}

Call-Script -Objective 'Install OpenSSH Server' -Script $ScriptBlock
