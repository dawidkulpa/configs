# Balanced profile for Mellanox ConnectX-4 Lx (your "Ethernet 9")
# Goal: keep 10G throughput while trimming latency/jitter.
# Run in an elevated PowerShell window.

# --- SETTINGS YOU MAY CHANGE ---
$IfName     = "Ethernet 9"
$UsingHyperV = $true   # set $true if this NIC backs a Hyper‑V External vSwitch or uses VMQ/SR‑IOV
$TryFixRsc   = $true    # try to make RSC operational by disabling Packet Direct if it blocks RSC
# -------------------------------

# Backup current state to Desktop\nic-backup-YYYYMMDD-HHMMSS
$ts    = (Get-Date).ToString("yyyyMMdd-HHmmss")
$bak   = "$env:USERPROFILE\Desktop\nic-backup-$ts"
New-Item -ItemType Directory -Path $bak -Force | Out-Null
$adv   = Get-NetAdapterAdvancedProperty -Name $IfName | Select Name,DisplayName,DisplayValue,RegistryKeyword,RegistryValue
$base  = [pscustomobject]@{
  Basic   = (Get-NetAdapter -Name $IfName | Select Name,InterfaceDescription,Status,LinkSpeed,MacAddress,DriverVersion,DriverDate)
  Adv     = $adv
  RSS     = (Get-NetAdapterRss -Name $IfName)
  RSC     = (Get-NetAdapterRsc -Name $IfName)
  LSO     = (Get-NetAdapterLso -Name $IfName)
  MTU     = (Get-NetIPInterface -InterfaceAlias $IfName | Select InterfaceAlias,AddressFamily,NlMtu,InterfaceMetric)
  Tcp     = (netsh int tcp show global)
}
$base | ConvertTo-Json -Depth 6 | Set-Content "$bak\baseline.json" -Encoding UTF8
@(
"==== Basic ====",
($base.Basic | Format-List | Out-String),
"==== Advanced properties ====",
($adv | Sort DisplayName | Format-Table -Auto Name,DisplayName,DisplayValue,RegistryKeyword,RegistryValue | Out-String),
"==== RSS ====",
($base.RSS | Format-List | Out-String),
"==== RSC ====",
($base.RSC | Format-List | Out-String),
"==== LSO ====",
($base.LSO | Format-List | Out-String),
"==== IP MTU ====",
($base.MTU | Format-Table -Auto | Out-String),
"==== TCP global ====",
($base.Tcp | Out-String)
) | Set-Content "$bak\baseline.txt" -Encoding UTF8
Write-Host "Backup saved to $bak"

function Set-Adv {
  param([string]$Key,[string]$Val)
  try {
    Set-NetAdapterAdvancedProperty -Name $IfName -DisplayName $Key -DisplayValue $Val -NoRestart -ErrorAction Stop | Out-Null
    Write-Host "$Key = $Val"
  } catch {
    # Ignore if the property/value doesn't exist on this driver
  }
}

# 1) Keep throughput offloads ON
Set-NetAdapterLso -Name $IfName -IPv4Enabled $true -IPv6Enabled $true -NoRestart
Set-Adv "UDP Segmentation Offload(IPv4)" "Enabled"
Set-Adv "UDP Segmentation Offload(IPv6)" "Enabled"

# 2) RSS: 8 queues; move work off CPU0; keep locality
$cores  = (Get-CimInstance Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum
$maxCPU = [math]::Max(1,$cores-1)
try {
  Set-NetAdapterRss -Name $IfName -Enabled $true -NumberOfReceiveQueues 8 -BaseProcessorNumber 2 -MaxProcessorNumber $maxCPU -Profile Closest -ErrorAction Stop
} catch {}

# 3) Interrupt moderation: adaptive + low-latency profiles (balanced)
Set-Adv "Interrupt Moderation" "Enabled"
Set-Adv "Rx Interrupt Moderation Type" "Adaptive"
Set-Adv "Rx Interrupt Moderation Profile" "Low Latency"
Set-Adv "Tx Interrupt Moderation Profile" "Low Latency"
# (Receive Completion Method already Adaptive on your dump; leaving as-is)

# 4) Buffers: conservative RX (512), ample TX (2048)
Set-Adv "Receive Buffers" "512"   # if you see drops under load, raise to 1024
Set-Adv "Send Buffers"    "2048"

# 5) Flow control: prefer RX only to avoid network-wide pauses
#Set-Adv "Flow Control" "Rx Only"

# 6) QoS/VLAN: disable if not needed (toggle off when not using DCB/802.1p/VLAN tagging)
if (-not $UsingHyperV) {
  Set-Adv "Quality Of Service" "Disabled"
  Set-Adv "Priority & Vlan Tag" "Priority & VLAN Disabled"
}

# 7) Virtualization features: disable if not using Hyper‑V/VMs on this NIC
if (-not $UsingHyperV) {
  Set-Adv "Virtual Machine Queues" "Disabled"
  Set-Adv "Virtual Switch RSS"     "Disabled"
  Set-Adv "SR-IOV"                 "Disabled"
}

# 8) RSC: your dump shows RSC enabled but non-operational (NDISCompatibility).
# Optionally try to make it operational by disabling Packet Direct, then re-enable RSC.
if ($TryFixRsc) {
  $r = Get-NetAdapterRsc -Name $IfName
  $blocked = (($r.IPv4Enabled -and -not $r.IPv4OperationalState -and $r.IPv4FailureReason -eq 'NDISCompatibility') -or
              ($r.IPv6Enabled -and -not $r.IPv6OperationalState -and $r.IPv6FailureReason -eq 'NDISCompatibility'))
  if ($blocked) {
    Set-Adv "Packet Direct" "Disabled"
    Disable-NetAdapterRsc -Name $IfName -IPv4 -IPv6 -ErrorAction SilentlyContinue
    Enable-NetAdapterRsc  -Name $IfName -IPv4 -IPv6 -ErrorAction SilentlyContinue
  }
}

# 9) Jumbo frames (optional; only if end-to-end supports it) — leave commented
# Set-Adv "Jumbo Packet" "9014"
# Set-NetIPInterface -InterfaceAlias $IfName -NlMtu 9000

# Apply vendor settings
Disable-NetAdapter -Name $IfName -Confirm:$false
Start-Sleep 2
Enable-NetAdapter -Name $IfName

# Show summary
Get-NetAdapter -Name $IfName | Select Name,Status,LinkSpeed | Format-Table -Auto
Get-NetAdapterRss -Name $IfName | Format-List Name,Enabled,NumberOfReceiveQueues,BaseProcessorNumber,MaxProcessorNumber,Profile
Get-NetAdapterAdvancedProperty -Name $IfName |
  Where-Object DisplayName -in @(
    "Interrupt Moderation","Rx Interrupt Moderation Type","Rx Interrupt Moderation Profile","Tx Interrupt Moderation Profile",
    "Flow Control","Quality Of Service","Priority & Vlan Tag","Virtual Machine Queues","Virtual Switch RSS","SR-IOV","Packet Direct",
    "Receive Buffers","Send Buffers","Jumbo Packet"
  ) | Sort DisplayName | Format-Table -Auto Name,DisplayName,DisplayValue
Get-NetAdapterRsc -Name $IfName | Format-List