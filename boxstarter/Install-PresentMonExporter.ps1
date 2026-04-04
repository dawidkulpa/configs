#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs and configures PresentMon metrics exporter for Prometheus.

.DESCRIPTION
    Standalone script to install the PresentMon game performance metrics exporter.
    Requires Python 3 and Chocolatey to be already installed on the system.

.NOTES
    Run from elevated PowerShell in the boxstarter/ directory.
#>

$PresentMonVersion = "2.4.1"
$PresentMonExporterDir = "C:\Apps\PresentMonExporter"

# Install NSSM (service manager)
choco install nssm -y

# Install Python Prometheus client
pip install prometheus_client

# Create exporter directory
New-Item -Path $PresentMonExporterDir -ItemType directory -Force

# Download PresentMon CLI
$PresentMonUrl = "https://github.com/GameTechDev/PresentMon/releases/download/v$PresentMonVersion/PresentMon-$PresentMonVersion-x64.exe"
if (-Not (Test-Path "$PresentMonExporterDir\PresentMon.exe")) {
    Invoke-WebRequest -Uri $PresentMonUrl -OutFile "$PresentMonExporterDir\PresentMon.exe"
}

# Copy exporter script
Copy-Item -Path "$PSScriptRoot\presentmon_exporter.py" -Destination "$PresentMonExporterDir\presentmon_exporter.py" -Force

# Register PresentMon exporter as a Windows service
$svcName = "PresentMonExporter"
$existingService = Get-Service -Name $svcName -ErrorAction SilentlyContinue
if (-Not $existingService) {
    nssm install $svcName python "$PresentMonExporterDir\presentmon_exporter.py"
    nssm set $svcName ObjectName LocalSystem
    nssm set $svcName AppDirectory $PresentMonExporterDir
    nssm set $svcName AppStdout "$PresentMonExporterDir\exporter.log"
    nssm set $svcName AppStderr "$PresentMonExporterDir\exporter.log"
    nssm set $svcName AppRotateFiles 1
    nssm set $svcName AppRotateBytes 1048576
}
$svcState = (Get-Service -Name $svcName -ErrorAction SilentlyContinue).Status
if ($svcState -eq 'Running') {
    nssm restart $svcName
} elseif ($svcState -ne $null) {
    nssm start $svcName
}
