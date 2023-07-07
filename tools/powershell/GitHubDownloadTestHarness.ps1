[CmdletBinding()]
param (
     [Parameter(Mandatory=$false)][string]$GhUser        = 'tamu-edu'
    ,[Parameter(Mandatory=$false)][string]$GhRepo        = 'CLAT-Windows-Admin'
    ,[Parameter(Mandatory=$false)][string]$GhBranch      = 'main'
    ,[Parameter(Mandatory=$false)][string]$GhFile        = 'sshd_config'
    ,[Parameter(Mandatory=$false)][string]$GhPath        = "Server%20Configuration/files"
    ,[Parameter(Mandatory=$false)][string]$GhAccessToken = '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'
    ,[Parameter(Mandatory=$false)][string]$DownloadPath  = 'C:\temp'
)

$FilePath = "$GhPath/$GhFile"
$GhFileUrl     = "https://raw.githubusercontent.com/$GhUser/$GhRepo/main/$FilePath"

# Classic token
$GhFileType      = 'application/vnd.github+json'
$GhHeaders        = @{
    Authorization = "token $GhAccessToken"
    Accept        = $GhFileType
    "X-GitHub-Api-Version" = '2022-11-28'
}

$DownloadFile = "$DownloadPath\$GhFile"

Invoke-WebRequest -Uri $GhFileUrl -Headers $GhHeaders  -OutFile $DownloadFile
