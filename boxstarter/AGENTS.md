# WINDOWS CONFIGURATION

## OVERVIEW

Boxstarter/Chocolatey-based automation for Windows developer machine setup. Single-run provisioning script.

## FILES

- `Boxstarter.ps1` — Full machine setup: privacy settings, UI tweaks, bloatware removal, driver installs, dev tools, runtimes, entertainment
- `pc-mellanox-config.ps1` — Mellanox network adapter configuration (standalone, not called by Boxstarter.ps1)
- `presentmon_exporter.py` — Python script: PresentMon CSV → Prometheus metrics exporter. Deployed to `C:\Apps\PresentMonExporter\` by Boxstarter.ps1. Run `python presentmon_exporter.py --test` to validate.
- `presentmon_blacklist.txt` — Plain-text application blacklist for PresentMon exporter. One exe name per line, `#` comments supported. Deployed to `C:\Apps\PresentMonExporter\` by install script.

## DEPLOY

```powershell
# First install Boxstarter:
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force

# Then run from elevated PowerShell:
Install-BoxstarterPackage -PackageName <path/to/Boxstarter.ps1>

# Or remotely:
Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/dawidkulpa/configs/master/boxstarter/Boxstarter.ps1
```

## WHAT BOXSTARTER.PS1 DOES (in order)

1. **Privacy/Security**: Disables Bing search, Cortana, advertising ID, WiFi Sense, SMBv1. Enables Developer Mode
2. **UI Preferences**: Explorer tweaks (show hidden files, extensions, full path), Quick Access → Favorites behavior, disable lock screen, small taskbar
3. **Bloatware Removal**: ~25 Microsoft/third-party apps (games, Bing apps, Skype, Clipchamp, etc.)
4. **Power Settings**: Disable hibernation, never sleep on AC, SSD-optimized (disable defrag)
5. **Windows Features**: WSL, Virtual Machine Platform, Telnet Client
6. **Drivers**: vcredist140, Logitech G Hub, Samsung Magician, MSI Afterburner, NZXT CAM, HWiNFO
7. **Runtimes**: .NET 3.5/4.5, PowerShell Core, Go, Python 3, FNM + Node.js LTS
8. **Tools**: 7zip, curl, wget, VSCode, Termius, XPipe, PowerToys, Google Drive, Fusion 360, Yubikey
9. **Entertainment**: VLC, Steam, Discord
10. **Monitoring**: PresentMon CLI download, Python prometheus_client install, NSSM service registration for PresentMon metrics exporter (port 4446)
11. **Cleanup**: Re-enable UAC, Windows Update, auto-reboot

## CONVENTIONS

- Uses `cup` (Chocolatey upgrade) with `--cacheLocation` for long-path workaround (`C:\Temp`)
- `addToProfileScript` helper writes to OneDrive-synced PowerShell profile
- Handles reboots between steps: `if (Test-PendingReboot) { Invoke-Reboot }`
- Nvidia driver install and Docker Desktop commented out — cause bootloop/issues
- Chocolatey auto-update configured weekly (Sunday 11:00)
- FNM (Fast Node Manager) used instead of nvm — matches macOS/Nix setup
- PresentMon exporter uses env vars for runtime config (`PRESENTMON_PATH`, `PRESENTMON_METRICS_PORT`, `PRESENTMON_STALE_TIMEOUT`, `PRESENTMON_BLACKLIST_PATH`). Application blacklist stored as plain-text file (`presentmon_blacklist.txt`) for git tracking.
- All PresentMon metrics prefixed with `presentmon_` to avoid collision with OhmGraphite metrics

## MONITORING

PresentMon game performance metrics pipeline:

- **Architecture**: Python exporter (`presentmon_exporter.py`) spawns PresentMon CLI as subprocess, parses CSV frame data, serves Prometheus `/metrics` on port 4446
- **Metrics prefix**: `presentmon_` — complementary to OhmGraphite (hardware sensors on port 4445)
- **Service**: `PresentMonExporter` (NSSM-managed Windows service, runs as LocalSystem for ETW access)
- **PresentMon version**: Pinned in both `presentmon_exporter.py` (`PRESENTMON_VERSION`) and `Boxstarter.ps1` (`$PresentMonVersion`)
- **Stale cleanup**: Metrics for apps not seen in 60 seconds are automatically removed
- **Self-test**: `python presentmon_exporter.py --test` — validates CSV parsing, metrics, and endpoint without requiring PresentMon binary or live games
- **Config**: Environment variables `PRESENTMON_PATH`, `PRESENTMON_METRICS_PORT`, `PRESENTMON_STALE_TIMEOUT`, `PRESENTMON_BLACKLIST_PATH`
- **Blacklist**: `presentmon_blacklist.txt` — plain-text file, one exe per line. Entries passed as `--exclude` args to PresentMon CLI (filters at ETW capture level). Python fallback filter as defense-in-depth. File auto-reloaded on PresentMon subprocess restart.
- **Install dir**: `C:\Apps\PresentMonExporter\`

## ANTI-PATTERNS

- **DO NOT** uncomment `geforce-game-ready-driver` or `geforce-experience` — causes bootloop
- **DO NOT** uncomment `docker-desktop` — causes issues (use WSL Docker instead)
- **DO NOT** add YAML/JSON/INI config files to the exporter — use env vars for runtime config. Exception: `presentmon_blacklist.txt` is a plain-text blacklist tracked in git.
- **DO NOT** use `pid` or `window_title` as Prometheus labels — causes cardinality explosion
- **DO NOT** add whitelist-style process filtering — use the blacklist file (`presentmon_blacklist.txt`) with `--exclude` CLI args instead. Do not add regex/wildcard matching.
