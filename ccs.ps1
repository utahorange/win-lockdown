write-output "starting firewall script"

# ---ENABLING FIREWALL---
Set-Service -Name mpssvc -StartupType Automatic -Status Running -Confirm $false
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow
Disable-NetFirewallRule -group "Remote Assistance"

# ---DISABLING GUEST/ADMINISTRATOR ACCOUNTS---
Disable-LocalUser -Name "Administrator"
Disable-LocalUser -Name "Guest"

Disable-ADAccount -Name "Administrator"
Disable-ADAccount -Name "Guest"

# ---ENABLING/DISABLING USER ACCOUNTS---
Disable-LocalUser
Disable-ADAccount

write-output "rmbr to create admins.txt, users.txt"

foreach($line in [System.IO.File]::ReadLines("admins.txt"))
{
    Enable-LocalUser -Name $line
    Enable-ADAccount -Name $line
    Add-LocalGroupMember -Group "Administrators" -Member $line 
    Add-ADGroupMember - Group "Administrators" - Member $line
}
foreach($line in [System.IO.File]::ReadLines("users.txt"))
{
    Enable-LocalUser -Name $line
    Enable-ADAccount -Name $line
}

# ---UAC---
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v FilterAdministratorToken /d 1 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v EnableUIADesktopToggle /d 0 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v ConsentPromptBehaviorUser /d 0 /f 
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v ValidateAdminCodeSignatures /d 1 /f 
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v EnableSecureUIAPaths /d 1 /f 
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v EnableLUA /d 1 /f 
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /t REG_DWORD /v EnableVirtualization /d 0 /f 

# ---AUDIT POLICY---
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Detailed Tracking" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable

# ---IMPORTING SECPOL.INF---
$dir ='' # DO THIS
Invoke-WebRequest 'https://raw.githubusercontent.com/prince-of-tennis/delphinium/main/secpol.inf' -OutFile $dir
secedit.exe /configure /db %windir%\security\local.sdb /cfg $dir

# ---WINDOWS DEFENDER---
Set-Service -Name WinDefend -StartupType Automatic -Status Running -Confirm $false
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableHeuristics" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "ScanWithAntiVirus" /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "CheckForSignaturesBeforeRunningScan" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableGenericRePorts" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "LocalSettingOverrideSpynetReporting" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 5 /F

# ---MISC HARDENING---

# unshare C: drive
net share C:\ /delete
# enable Data Execution Prevention
BCDEDIT /SET {CURRENT} NX ALWAYSON

# enable smartscreen
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System /t REG_DWORD /v EnableSmartScreen /d 1 /f
# disable autoplay
reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers  /v DisableAutoplay /t REG_DWORD /d 1
# enable autoupdate
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 0
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v AUOptions /t REG_DWORD /d 3
# user cannot request assistance from a friend or a support professional.
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance /v fAllowToGetHelp /t REG_DWORD /d 0
# enabling firewall via registry
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile /v EnableFirewall /t REG_DWORD /d 1
#disable remote desktop
reg add HKLM\SYSTEM\CurrentControlSet\Control\"Terminal Server" /t REG_DWORD /v fDenyTSConnections /d 0 /f
reg add HKLM\SYSTEM\CurrentControlSet\Control\"Terminal Server"/t REG_DWORD /v fSingleSessionPerUser /d 1 /f
# disable auto admin login
reg add HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon /v Autoadminlogin /t REG_SZ /d 0 /f
# disable ctrl-alt-delete to login
reg add HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon /v DisableCAD /t REG_DWORD /d 1 /f
# disable WDigest
reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest /v UseLogonCredential /t REG_DWORD /d 0

# ---DISABLING FEATURES/SERVICES---
write-output "beginning to disable services - check readme for critical services"

set-service eventlog -start a -status running
set-service snmptrap -start d -status stopped
set-service iphlpsvc -start d -status stopped
Get-Service -Name WinRM | Stop-Service -Force
Set-Service -Name WinRM -StartupType Disabled -Status Stopped -Confirm $false

Set-Service WSearch -StartupType Disabled
Stop-Service WSearch 

Set-Service iphlpsvc -StartupType Disabled
Stop-Service iphlpsvc 

Disable-PSRemoting -Force
Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart  
Disable-WindowsOptionalFeature -Online -FeatureName TelnetServer -NoRestart  

Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart  
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force 

# ---ENABLING FEATURES/SERVICES---
Set-Service W32Time -StartupType Automatic
Start-Service W32Time

#Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force

# ---SETTING LOCAL/DOMAIN PASSWORDS---
Get-LocalUser | Set-LocalUser -Password (Read-Host -AsSecureString "local pass: ")
Get-ADUser | Set-ADUser -Password (Read-Host -AsSecureString "AD pass:")