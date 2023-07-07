## Notes from running Configure-AnsibleClient on multiple machines

### If there is an issue with using SSL and TLS 1.2 (especially true for Windows Server 2012/2012R2)

```powershell
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
```

### If you get an error about downloading the file from the Github (especially true for Windows Server 2012/2012R2)

#### Turn off IE enhanced security configurtion

```powershell
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer -Force
```

### Get the script zip file from GitHub

```powershell
mkdir c:\temp -ErrorAction SilentlyContinue ;Invoke-WebRequest -Uri "https://github.com/tamu-edu/clat-common-configs/archive/refs/heads/main.zip" -OutFile c:\temp\common-configs.zip
```
###  To unzip the file

#### PowerShell 5.1 and later unzip

```powershell
Expand-Archive c:\temp\common-configs.zip c:\temp
```

#### Pre PowerShell 5.1 unzip

```powershell
$zipFile = "c:\temp\common-configs.zip"

$destination = "c:\temp"

$shellApp = New-Object -ComObject Shell.Application
$zip = $shellApp.NameSpace($zipFile)
$destinationFolder = $shellApp.NameSpace($destination)

$destinationFolder.CopyHere($zip.Items())
```

### Wait for the extraction to complete

```powershell
while ($destinationFolder.Items().Count -lt $zip.Items().Count) {
    Start-Sleep -Milliseconds 500
}
```
### Edit Install-OpenSSH.ps1 

### Run the script

```powershell
cd C:\temp\clat-common-configs-add-changes-from-clat-windows-admin\tools\powershell\

. .\Configure-AnsibleClient.ps1 -Verbose
```

