
# Purpose:  PowerShell Script to Install EndGame
#
# Notes:    Check to see if SERVICE is INSTALLED and RUNNING Before Installing
#
# Special:  Got original Install Script from Michael Esparza (esparza@tamu.edu)
#           Added a CHECK for Install/Running BEFORE Doing an Install 
#
#
# Revision History
# ---------------------------------------------------------------
# Init Date        Comments
# WSW  09/21/2022  Created Script
#

$ServiceName  = "eSensor" # Service that we want to Check to see if it's running BEFORE we install


# TEST Cases
#$ServiceName  = "eSensor" # Service that is Running
#$ServiceName  = "DPMRA"   # Service NOT Running
#$ServiceName  = "XXXXX"   # Non-Existing Service

$oService  = Get-Service -Name $ServiceName


# If Service Found and Running, Just EXIT Script and DO NOT Install
if ( $oService.Status -eq 'Running' )
   {
   echo "Service Found and Running. Just Exit Script!"
   Exit
   }


# Service NOT Found or NOT Running, Try to re-install
echo "Starting Install Now..."

# ----------------------------------------------------------------------
# Got original Install Script from Michael Esparza (esparza@tamu.edu)
# ----------------------------------------------------------------------

$WebClient = New-Object System.Net.WebClient
if ($?) {
    $WebClient.DownloadFile('https://repo.crd.tamus.edu/eg/eg_win/SensorWinInstaller.exe','C:\windows\temp\SensorWinInstaller.exe')
    if ($?) {
        $WebClient.DownloadFile('https://repo.crd.tamus.edu/eg/eg_win/SensorWinInstaller.cfg','C:\windows\temp\SensorWinInstaller.cfg')
        if ($?) {
                Start-Process -Filepath 'C:\windows\temp\SensorWinInstaller.exe' -ArgumentList '-c C:\windows\temp\SensorWinInstaller.cfg -f -k F8B1A30164F910EF83C6 -d false -l c:\windows\temp\EndgameSetup.log'
                }
            }
        }