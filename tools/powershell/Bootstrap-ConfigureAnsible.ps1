$os = Get-WmiObject -Class Win32_OperatingSystem

$Global:WindowsVersion = ''
switch -wildcard ($os.Caption) {
    "*Windows Server 2012*" { $WindowsVersion = "Windows Server 2012" }
    "*Windows Server 2016*" { $WindowsVersion = "Windows Server 2016" }
    "*Windows Server 2019*" { $WindowsVersion = "Windows Server 2019" }
    "*Windows Server 2022*" { $WindowsVersion = "Windows Server 2022" }
    Default { $WindowsVersion = "Unknown" }
}

if ($WindowsVersion -in ("Windows Server 2012", "Windows Server 2016")){
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
}

# Turn off IE Enhanced Security
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer -Force

# Is chocolatey installed
$ChocoLoca = where.exe choco.exe 2>&1
if ($LASTEXITCODE){
    # Chocolatey is not installed
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;

    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Do nothing.  IEX is behaving wierd when not in a try/catch"
    }

    $ChocoLoca = where.exe choco.exe 2>&1
    if ($LASTEXITCODE){
        Read-Host "Restart this script after this server reboots (press enter to Reboot)"
        shutdown /r /t 0
    }
}

# Install PowerShell 5.1
if (-NOT (choco list PowerShell | where {$_ -match 'PowerShell 5\.1.*'})){
    $null = choco install PowerShell --y
    Read-Host "Restart this script after this server reboots (press enter to Reboot)"
    shutdown /r /t 0
}

mkdir c:\temp -ErrorAction SilentlyContinue ;Invoke-WebRequest -Uri "https://github.com/tamu-edu/clat-common-configs/archive/refs/heads/main.zip" -OutFile c:\temp\common-configs.zip

$zipFile = "c:\temp\common-configs.zip"

$destination = "c:\temp"

$shellApp = New-Object -ComObject Shell.Application
$zip = $shellApp.NameSpace($zipFile)
$destinationFolder = $shellApp.NameSpace($destination)

$destinationFolder.CopyHere($zip.Items())

# Wait for the extraction to complete
while ($destinationFolder.Items().Count -lt $zip.Items().Count) {
    Start-Sleep -Milliseconds 500
}

cd C:\temp\clat-common-configs-main\tools\powershell

. .\Configure-AnsibleClient.ps1 -Verbose