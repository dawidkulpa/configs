# Description: Boxstarter Script for Developer Machines
# Author: https://github.com/timmes, edited by https://github.com/dawidkulpa
#
# To run this script, you first have to install boxstarter using the following command (NOTE the "." below is required):
# 	. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force
# Learn more: http://boxstarter.org/Learn/WebLauncher
#
# Run this BoxstarterDevFull.ps1 script by calling the following from **elevated** powershell:
#   example: Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/dawidkulpa/configs/master/windows/Boxstarter.ps1 -DisableReboots


Update-ExecutionPolicy -Policy RemoteSigned

# Workaround for nested chocolatey folders resulting in path too long error
$ChocoCachePath = "C:\Temp"
New-Item -Path $ChocoCachePath -ItemType directory -Force

# Temporary
Disable-UAC
Disable-MicrosoftUpdate

# General boxstarter settings #
$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

#############################
# Privacy / Security Settings
#############################
Disable-BingSearch
Disable-GameBarTips

# Privacy: Let apps use my advertising ID: Disable
If (-Not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
    New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo | Out-Null
}
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Type DWord -Value 0

# WiFi Sense: HotSpot Sharing: Disable
If (-Not (Test-Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
    New-Item -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting | Out-Null
}
Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting -Name value -Type DWord -Value 0

# WiFi Sense: Shared HotSpot Auto-Connect: Disable
Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots -Name value -Type DWord -Value 0

# Start Menu: Disable Bing Search Results
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name BingSearchEnabled -Type DWord -Value 0

# Start Menu: Disable Cortana 
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'Windows Search' -ItemType Key
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name AllowCortana -Type DWORD -Value 0

# Disable SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol

############################
# Personal Preferences on UI
############################
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions -EnableShowFullPathInTitleBar
Set-BoxstarterTaskbarOptions -Size Small

# Move "Documents" folder to OneDrive
Move-LibraryDirectory "Personal" "$HOME\OneDrive\Dokumenty"

# Disable defrag (no need when having an SSD)
Get-ScheduledTask -TaskName *defrag* | Disable-ScheduledTask

# Change Explorer home screen back to "This PC"
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Type DWord -Value 1

# Better File Explorer
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1		
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1		
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarMode -Value 2

# These make "Quick Access" behave much closer to the old "Favorites"
# Disable Quick Access: Recent Files
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Type DWord -Value 0
# Disable Quick Access: Frequent Folders
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Type DWord -Value 0

# Disable the Lock Screen (the one before password prompt - to prevent dropping the first character)
If (-Not (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization)) {
	New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows -Name Personalization | Out-Null
}
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Name NoLockScreen -Type DWord -Value 1

# Turn off People in Taskbar
If (-Not (Test-Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
    New-Item -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People | Out-Null
}
Set-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name PeopleBand -Type DWord -Value 0

###############################
# Windows 10 Metro App Removals
###############################

# BubbleWitch
Get-AppxPackage *BubbleWitch* | Remove-AppxPackage

# Candy Crush
Get-AppxPackage king.com.CandyCrush* | Remove-AppxPackage

# Dell
Get-AppxPackage *Dell* | Remove-AppxPackage

# Disney Magic Kingdom
Get-AppxPackage *DisneyMagicKingdom* | Remove-AppxPackage

# Dropbox
Get-AppxPackage *Dropbox* | Remove-AppxPackage

# Facebook
Get-AppxPackage *Facebook* | Remove-AppxPackage

# Feedback Hub
Get-AppxPackage Microsoft.WindowsFeedbackHub | Remove-AppxPackage

# Get Started
Get-AppxPackage Microsoft.Getstarted | Remove-AppxPackage

# Hidden City: Hidden Object Adventure
Get-AppxPackage *HiddenCityMysteryofShadows* | Remove-AppxPackage

# Keeper
Get-AppxPackage *Keeper* | Remove-AppxPackage

# Mail & Calendar
Get-AppxPackage microsoft.windowscommunicationsapps | Remove-AppxPackage

# Maps
Get-AppxPackage Microsoft.WindowsMaps | Remove-AppxPackage

# March of Empires
Get-AppxPackage *MarchofEmpires* | Remove-AppxPackage

# McAfee Security
Get-AppxPackage *McAfee* | Remove-AppxPackage

# Uninstall McAfee Security App
$mcafee = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "McAfee Security" } | select UninstallString
if ($mcafee) {
	$mcafee = $mcafee.UninstallString -Replace "C:\Program Files\McAfee\MSC\mcuihost.exe",""
	Write "Uninstalling McAfee..."
	start-process "C:\Program Files\McAfee\MSC\mcuihost.exe" -arg "$mcafee" -Wait
}

# Minecraft
Get-AppxPackage *Minecraft* | Remove-AppxPackage

# Netflix
Get-AppxPackage *Netflix* | Remove-AppxPackage

# Office Hub
Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage

# One Connect
Get-AppxPackage Microsoft.OneConnect | Remove-AppxPackage

# OneNote
Get-AppxPackage Microsoft.Office.OneNote | Remove-AppxPackage

# People
Get-AppxPackage Microsoft.People | Remove-AppxPackage

# Plex
Get-AppxPackage *Plex* | Remove-AppxPackage

# Skype (Metro version)
Get-AppxPackage Microsoft.SkypeApp | Remove-AppxPackage

# Sound Recorder
Get-AppxPackage Microsoft.WindowsSoundRecorder | Remove-AppxPackage

# Solitaire
Get-AppxPackage *Solitaire* | Remove-AppxPackage

# Sticky Notes
Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage

# Sway
Get-AppxPackage Microsoft.Office.Sway | Remove-AppxPackage

# Twitter
Get-AppxPackage *Twitter* | Remove-AppxPackage

# Zune Music, Movies & TV
Get-AppxPackage Microsoft.ZuneMusic | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage

###############################
# Power Settings
###############################

# Turn off hibernation
powercfg /H OFF

# Change Power saving options (ac=plugged in dc=battery)
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 15
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 30
powercfg -change -disk-timeout-ac 0
powercfg -change -disk-timeout-dc 0
powercfg -change -hibernate-timeout-ac 0

###################################
# Windows Subsystems/Roles/Features
###################################

cinst Microsoft-Hyper-V-All -source windowsFeatures
cinst Microsoft-Windows-Subsystem-Linux -source windowsFeatures
cinst TelnetClient -source windowsFeatures

cinst IIS-ApplicationDevelopment -source windowsfeatures
cinst IIS-ApplicationInit -source windowsfeatures
cinst IIS-ASPNET -source windowsfeatures
cinst IIS-ASPNET45 -source windowsfeatures
cinst IIS-BasicAuthentication -source windowsfeatures
cinst IIS-ClientCertificateMappingAuthentication -source windowsfeatures
cinst IIS-CommonHttpFeatures -source windowsfeatures
cinst IIS-CustomLogging -source windowsfeatures
cinst IIS-DefaultDocument -source windowsfeatures
cinst IIS-DigestAuthentication -source windowsfeatures
cinst IIS-DirectoryBrowsing -source windowsfeatures
cinst IIS-HealthAndDiagnostics -source windowsfeatures
cinst IIS-HttpCompressionDynamic -source windowsfeatures
cinst IIS-HttpCompressionStatic -source windowsfeatures
cinst IIS-HttpErrors -source windowsfeatures
cinst IIS-HttpLogging -source windowsfeatures
cinst IIS-HttpRedirect -source windowsfeatures
cinst IIS-HttpTracing -source windowsfeatures
cinst IIS-IISCertificateMappingAuthentication -source windowsfeatures
cinst IIS-IPSecurity -source windowsfeatures
cinst IIS-ISAPIExtensions -source windowsfeatures
cinst IIS-ISAPIFilter -source windowsfeatures
cinst IIS-LoggingLibraries -source windowsfeatures
cinst IIS-ManagementConsole -source windowsfeatures
cinst IIS-ManagementScriptingTools -source windowsfeatures
cinst IIS-ManagementService -source windowsfeatures
cinst IIS-NetFxExtensibility -source windowsfeatures
cinst IIS-NetFxExtensibility45 -source windowsfeatures
cinst IIS-Performance -source windowsfeatures
cinst IIS-RequestFiltering -source windowsfeatures
cinst IIS-RequestMonitor -source windowsfeatures
cinst IIS-Security -source windowsfeatures
cinst IIS-StaticContent -source windowsfeatures
cinst IIS-URLAuthorization -source windowsfeatures
cinst IIS-WebServer -source windowsfeatures
cinst IIS-WebServerManagementTools -source windowsfeatures
cinst IIS-WebServerRole -source windowsfeatures
cinst IIS-WebSockets -source windowsfeatures
cinst IIS-WindowsAuthentication -source windowsfeatures

#######
# Drivers and hardware management
#######

# Install Visual C++ Redistributable 2015-2022
choco install vcredist140 -y

# Install Nvidia Drivers - currently disabled, as it failes and causes bootloop
# choco install geforce-game-ready-driver -y

# Install Logitech G Hub
choco install lghub -y

# Install Samsung Magician
choco install samsung-magician -y

# Install MSI Afterburner
choco install msiafterburner -y

# Install NZXT CAM
choco install nzxt -y

# Install HWiNFO
choco install hwinfo -y

############################
# .NET Framework
############################

# .NET 3.5
choco install dotnet3.5
if (Test-PendingReboot) { Invoke-Reboot }

# .NET 4.5
choco install dotnet4.5
if (Test-PendingReboot) { Invoke-Reboot }

##########
# PowerShell
##########

choco install powershell-core -y --install-arguments='"ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1"'

##########
# Browsers
##########

choco install googlechrome

##########
# Docker
##########

# Install Docker & Minikube
cup docker-desktop --cacheLocation $ChocoCachePath
cup docker-compose --cacheLocation $ChocoCachePath
cup minikube --cacheLocation $ChocoCachePath

#####
# Git
#####

# Install git & git credential manager
cup git --cacheLocation $ChocoCachePath
cup git-credential-manager-for-windows --cacheLocation $ChocoCachePath

# Install posh-git
pwsh -Command "Install-Module posh-git -Scope CurrentUser -Force"

# Add posh-git to PowerShell 7 profile
$profilePath = "$HOME\OneDrive\Dokumenty\PowerShell\Microsoft.PowerShell_profile.ps1"
$addToProfileScript = {
    if (!(Test-Path -Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force
    }
    Add-Content -Path $profilePath -Value 'Import-Module posh-git'
}

# Execute the script block in PowerShell 7 to ensure it uses the correct profile
pwsh -Command $addToProfileScript

#############################
# Runtime Environments & SDKs
#############################

# Install Go
cup golang --cacheLocation $ChocoCachePath

# Install Python 3
cup python3 --cacheLocation $ChocoCachePath

# Install NVM (Node Version Manager) and refresh environment
cup nvm --cacheLocation $ChocoCachePath
refreshenv

# Install latest LTS Node.js
pwsh -Command "nvm install lts"

#######
# Tools
#######

# Install Zip Tools
cup 7zip --cacheLocation $ChocoCachePath

# Install File Tools

# Install Data Transfer Tools
cup curl --cacheLocation $ChocoCachePath
cup wget --cacheLocation $ChocoCachePath

# Install Productivity Tools
choco install adobereader -y
choco install windirstat -y

# Install Development Tools
choco install visualstudiocode -y

# Install Termius
choco install termius -y

# Install PowerToys
choco install powertoys -y

# Install Google Drive
choco install googledrive -y --params "'/NoStart /NoGsuiteIcons'"

# Install Autodesk Fusion 360
choco install autodesk-fusion360 -y

# Install Yubikey software
choco install yubikey-manager -y
choco install yubico-authenticator -y

#######
# Entertainment
#######

# Install Geforce Experience - disabled, as it fails and causes bootloop
# choco install geforce-experience -y

# Install Media Tools
choco install vlc -y
choco install spotify -y

# Install Gaming Tools
choco install steam -y

# Install Communication Tools
choco install discord -y

#####################################
# Update Windows, reboot and clean up
#####################################

# Clean up the cache directory
Remove-Item $ChocoCachePath -Recurse

#--- Restore Temporary Settings ---
choco feature disable -n=allowGlobalConfirmation
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
Enable-UAC