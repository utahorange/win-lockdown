Start-Transcript -Append ../logs/log.txt
Write-Output "|| Welcome to Win ||`n" - ForegroundColor Green

& $PSScriptRoot/recon.ps1

$installTools = Read-Host "Install tools? May take a while: [Y/N] (Default: N)"
if($installTools -eq "Y"){
    & $PSScriptRoot/install-tools.ps1
}

& $PSScriptRoot/enable-firewall.ps1
& $PSScriptRoot/enable-defender.ps1

$SecurePassword = ConvertTo-SecureString -String 'CyberPatriot123!@#' -AsPlainText -Force
& $PSScriptRoot/local-users.ps1 -Password $SecurePassword
$ad = Read-Host "Does this computer have AD? [Y/N] (Default: N)"
if($ad -eq "Y"){
    & $PSScriptRoot/ad-users.ps1 -Password $SecurePassword
}

& $PSScriptRoot/import-gpo.ps1
& $PSScriptRoot/import-secpol.ps1
& $PSScriptRoot/auditpol.ps1
& $PSScriptRoot/uac.ps1
<#
add check for if gpo break -> prob try/catch?

if gpo AND secpol breaks, run uac.ps1, auditpol.ps1
#>

& $PSScriptRoot/services.ps1

& $PSScriptRoot/remove-nondefaultshares.ps1 
bcdedit /set {current} nx AlwaysOn

$firefox = Read-Host "Is Firefox on this system? [Y/N] (Default: N)"
if($firefox -eq "Y"){
    &PSScriptRoot/configure-firefox.ps1
}

# view hidden files
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Hidden /t REG_DWORD /d 1 /f
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ShowSuperHidden /t REG_DWORD /d 1 /f
taskkill /f /im explorer.exe
Start-Sleep 2
Start-Process explorer.exe

Write-Output "|| ccs.ps1 finished ||`n" - ForegroundColor Green
Stop-Transcript
Invoke-Item ".../logs/log.txt"
