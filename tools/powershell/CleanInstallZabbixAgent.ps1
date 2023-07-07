# Reinstall Zabbix Agent 2
if (-NOT (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    throw 'This script must be run as Administrator ("run as Administrator")'
}

$ZabbixServer = "zabbix.geos.tamu.edu"
$ZabbixPort = 10050
$ZabbixDownloadUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.1/zabbix_agent2-6.4.1-windows-amd64-openssl.msi"
$ZabbixServiceName = "Zabbix Agent 2"

$MsiPackage = "ZabbixAgent.msi"

$LogPath = $env:TEMP
$LogFilePath = "$LogPath\ZabbixUninstall.log"

$MsiPath = "C:\temp"
$MsiFilePath = "$MsiPath\$MsiPackage"

if(-NOT (Test-Path $MsiPath -ErrorAction SilentlyContinue)){
    try {
        $null = mkdir $MsiPath
    } catch {
        throw
    }
}

if(-NOT (Test-Path $MsiFilePath -ErrorAction SilentlyContinue)){
    $TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol

    Write-Host "Downloading the Zabbix agent"
    $WebClient = New-Object System.Net.WebClient
    try {
        $WebClient.DownloadFile($ZabbixDownloadUrl,$MsiFilePath)
    } catch {
        throw
    }
}


if ((Get-Service "Zabbix Agent 2" -ErrorAction SilentlyContinue)) {
    msiexec /l*v $LogFilePath /uninstall $MsiFilePath /QN
    Write-Host "Checking for service to be removed: " -NoNewline
    while((Get-Service $ZabbixServiceName -ErrorAction SilentlyContinue)){
        Start-Sleep 2
        Write-Host "." -NoNewline
    }
    Write-Host ""
}

$LogFilePath = "$LogPath\ZabbixUninstall.log"

msiexec /l*v $LogFilePath /i $MsiFilePath SERVER=$ZabbixServer SERVERACTIVE=$ZabbixServer LISTENPORT=$ZabbixPort /QN
Write-Host "Checking for service to be installed: " -NoNewline
while(-NOT(Get-Service $ServiceName -ErrorAction SilentlyContinue) ){
    Start-Sleep 2
    Write-Host "." -NoNewline
}
