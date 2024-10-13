#* Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

if (-not $global:canConnectToGitHub) {
  Write-Host "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
  return
}

try {
  $url = "https://raw.githubusercontent.com/PantiesIsStoopid/Powershell/refs/heads/master/Microsoft.PowerShell_profile.ps1"
  $oldhash = Get-FileHash $PROFILE
  Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
  $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
  if ($newhash.Hash -ne $oldhash.Hash) {
    Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
    Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
  }
} catch {
  Write-Error "Unable to check for `$profile updates"
} finally {
  Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
}

if (-not $global:canConnectToGitHub) {
  Write-Host "Skipping PowerShell update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
  return
}

try {
  Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
  $updateNeeded = $false
  $currentVersion = $PSVersionTable.PSVersion.ToString()
  $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
  $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
  $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
  if ($currentVersion -lt $latestVersion) {
    $updateNeeded = $true
  }

  if ($updateNeeded) {
    Write-Host "Updating PowerShell..." -ForegroundColor Yellow
    winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
    Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
  } else {
    Write-Host "Your PowerShell is up to date." -ForegroundColor Green
  }
} catch {
  Write-Error "Failed to update PowerShell. Error: $_"
}

#* Opt out of PowerShell telemetry
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
  [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

#* Import Modules and External Profiles
#* Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
  Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
}

# Import the module
Import-Module -Name Terminal-Icons -ErrorAction Stop

# Import Chocolatey profile if it exists
$ChocolateyProfile = Join-Path -Path $env:ChocolateyInstall -ChildPath "helpers\chocolateyProfile.psm1"
if (Test-Path -Path $ChocolateyProfile) {
  Import-Module -Name $ChocolateyProfile -ErrorAction Stop
}

#* Clear the console
Clear-Host

#* Function to identify the terminal
function TerminalType {
  switch ($env:TERM_PROGRAM) {
    "vscode" { return "Visual Studio Code Terminal" }
    "Apple_Terminal" { return "Apple Terminal" }
    "iTerm.app" { return "iTerm" }
    { $env:ConEmuANSI } { return "ConEmu" }
    "Hyper" { return "Hyper" }
    default { return $Host.Name -eq "ConsoleHost" ? "Windows PowerShell" : "Unknown Terminal" }
  }
}

#* Get terminal type and print it
$terminalType = TerminalType
Write-Host "$terminalType" -ForegroundColor Yellow

#* Initialize Oh My Posh config
if (-not ($PSCmdlet.MyInvocation.PSCommandPath -match 'oh-my-posh')) {
  oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
}

#* Run neofetch if not in Visual Studio Code Terminal
if ($terminalType -ne "Visual Studio Code Terminal") {
  fastfetch -c neofetch.jsonc
}

#* Alias
function Touch {
  param (
    [string]$FileName
  )

  # Get the full path to the file (use current directory if only a file name is provided)
  $FullPath = Join-Path -Path (Get-Location) -ChildPath $FileName

  # If the file exists, update the last modified timestamp
  if (Test-Path -Path $FullPath) {
    (Get-Item $FullPath).LastWriteTime = Get-Date
  }
  # If the file doesn't exist, create an empty file in the current directory
  else {
    New-Item -Path $FullPath -ItemType File | Out-Null
  }
}

# Set directory to Documents
function Docs {
  Set-Location -Path "$HOME\Documents"
}

#* Set directory to Desktop
function Dtop {
  Set-Location -Path "$HOME\Desktop"
}

#* Move to the Downloads directory
function DLoads {
  Set-Location -Path "$HOME\Downloads"
}

#* List all files
function LA {
  Get-ChildItem -Path . -Force | Format-Table -AutoSize
}

#* List all files including hidden
function LL {
  Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize
}

#* Print Detailed System Information
function SysInfo {
  Get-ComputerInfo
}

#* Flush DNS Server
function FlushDNS {
  Clear-DnsClientCache
  Write-Host "DNS has been flushed" -ForegroundColor Green
}

#* Print the Public IP of the PC
function GetPubIP {
  (Invoke-WebRequest http://ifconfig.me/ip).Content
}

#* Print the Private IP of the PC
function GetPrivIP {
  param (
    [switch]$IncIPv6
  )

  # Get IP addresses for all network adapters
  $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias '*'
  
  # Optionally include IPv6 addresses
  if ($IncIPv6) {
    $ipAddresses += Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias '*'
  }

  # Format the output
  $ipAddresses | Format-Table -Property InterfaceAlias, IPAddress, AddressFamily -AutoSize
}

#* Run speedtest for internet
function Speedtest {  
  Write-Host "Running Speedtest" -ForegroundColor Cyan
  Invoke-RestMethod asheroto.com/speedtest | Invoke-Expression
  Write-Host "Pinging 1.1.1.1" -ForegroundColor Cyan
  ping 1.1.1.1
}

#* Open current directory in File Explorer
function FE {
  Invoke-Item (Get-Location)
}

#* Change directories to user's home
function Home {
  Set-Location -Path "$HOME"
}

#* Change directories to C drive
function Root {
  Set-Location C:\
}

#* Update function
function Update {
  #Update Powershell
  winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements

  # Update all known apps
  choco upgrade chocolatey
  choco upgrade all

  # Windows Updates
  Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
  Get-WindowsUpdate
}

#* Open the Chris Titus Tech Windows utility
function WinUtil {
  Invoke-WebRequest -useb https://christitus.com/win | Invoke-Expression
}

#* Reload Terminal profile
function ReloadProfile {
  & $profile
}

#* Check for corrupt files 
function SystemScan {
  # Run DISM scan
  Write-Host "Starting DISM scan..." -ForegroundColor Cyan
  try {
    dism /online /cleanup-image /checkhealth
    dism /online /cleanup-image /scanhealth
    dism /online /cleanup-image /restorehealth
    Write-Host "DISM scan completed successfully." -ForegroundColor Green
  } catch {
    Write-Host "DISM scan failed: $_" -ForegroundColor Red
  }

  # Run SFC scan
  Write-Host "Starting SFC scan..." -ForegroundColor Cyan
  try {
    sfc /scannow
    Write-Host "SFC scan completed successfully." -ForegroundColor Green
  } catch {
    Write-Host "SFC scan failed: $_" -ForegroundColor Red
  }

  Write-Host "Restoring original file permissions" -ForegroundColor Cyan
  icacls "C:\" /reset /t /c /l
  Write-Host "Restoring permissions completed successfully." -ForegroundColor Green
}

#* Function to clear system memory (not specifically standby RAM)
function ClearRAM {
  # Define URL and paths
  $url = "https://download.sysinternals.com/files/RAMMap.zip"
  $zipPath = "C:\RAMMap.zip"
  $extractPath = "C:\RAMMap"

  # Download RAMMap
  Invoke-WebRequest -Uri $url -OutFile $zipPath

  # Create extraction directory
  if (-Not (Test-Path $extractPath)) {
    New-Item -Path $extractPath -ItemType Directory | Out-Null
  }

  # Extract the ZIP file
  Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

  # Define the path to the executable
  $exePath = "C:\RAMMap\RAMMap.exe"

  # Run the executable and wait until it is closed
  Write-Host "Please open the app click 'Empty' then 'Empty Standby List' Then close the app."
  Start-Process -FilePath $exePath -Wait

  # Clean up by deleting RAMMap files
  Remove-Item -Path $zipPath -Force
  Remove-Item -Path $extractPath -Recurse -Force
}

#*Reinstall winget
function ReinstallWinget {
  #Uninstall winget
  Get-AppxPackage *Microsoft.DesktopAppInstaller* | Remove-AppxPackage

  #Install Winget
  Invoke-WebRequest -Uri "https://aka.ms/Microsoft.DesktopAppInstaller" -OutFile "$env:TEMP\AppInstaller.appxbundle"
  Add-AppxPackage -Path "$env:TEMP\AppInstaller.appxbundle"

  #Verify winget install
  winget --version
}

#*Empty Recycle Bin
function EmptyBin {
  Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
}

#* Calculate Pi
function CalcPi {
  # Display result
  $Pi = "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665223576580719180188"
  Write-Host "Calculating complete result in clipboard." -ForegroundColor Green
  Set-Clipboard -Value $Pi
}

#*Shutdown
function Shutdown {
  param (
    [switch]$Force
  )

  if ($Force) {
    # Forcefully shut down the PC
    Stop-Computer -Force -Confirm:$false
  } else {
    # Gracefully shut down the PC
    Stop-Computer -Confirm:$false
  }
}

#* RandomFact
function RandomFact {
  $url = "https://uselessfacts.jsph.pl/random.json?language=en"
  $response = Invoke-RestMethod -Uri $url
  Write-Host "Did you know? $($response.text)" 
}

#*Clear Caches
function ClearCache {
  # Clear Temporary Files
  Write-Host "Clearing temporary files..." -ForegroundColor Cyan
  $tempPath = [System.IO.Path]::GetTempPath()
  Remove-Item -Path $tempPath* -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Temporary files cleared." -ForegroundColor Green

  # Clear System Cache
  Write-Host "Clearing system cache..." -ForegroundColor Cyan
  #* Flush system cache
  [System.Diagnostics.Process]::Start('cmd.exe', '/c ipconfig /flushdns') | Out-Null
  Write-Host "System cache cleared." -ForegroundColor Green

  # Clear Internet Explorer Cache
  Write-Host "Clearing Internet Explorer cache..." -ForegroundColor Cyan
  RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
  Write-Host "Internet Explorer cache cleared." -ForegroundColor Green

  # Clear Microsoft Edge Cache
  Write-Host "Clearing Microsoft Edge cache..." -ForegroundColor Cyan
  $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
  Remove-Item -Path $edgeCachePath* -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Microsoft Edge cache cleared." -ForegroundColor Green
}

function CheatSheet {
  @"
PowerShell Cheatsheet
=====================

Basic Commands:
- Get-Command: Lists all cmdlets, functions, workflows, aliases installed.
- Get-Process: Retrieves a list of running processes.
- Start-Process: Starts a process.
- Stop-Process: Stops a process.
- Get-Service: Lists all services.
- Start-Service: Starts a service.
- Stop-Service: Stops a service.
- Restart-Service: Restarts a service.

File and Directory Management:
- Get-ChildItem: Lists items in a directory (alias: ls, dir).
- Set-Location: Changes the current directory (alias: cd).
- Copy-Item: Copies an item from one location to another.
- Move-Item: Moves an item from one location to another.
- Remove-Item: Deletes an item.
- New-Item: Creates a new item (file, directory, etc.).
- Get-Content: Reads content of a file.
- Set-Content: Writes or replaces content in a file.
- Add-Content: Appends content to a file.

System Information:
- Get-Location: Displays the current directory.
"@
}

#* Help Function
function ShowHelp {
  @"
PowerShell Profile Help
=======================

Directory Navigation:
- Touch: Create a file in your current directory (FileName.Ext).
- Docs: Changes the current directory to the user's Documents folder.
- Dtop: Changes the current directory to the user's Desktop folder.
- DLoads: Changes the current directory to the user's Downloads folder.
- Home: Changes directories to the user's home.
- Root: Changes directories to the C: drive.

File and System Information:
- LA: Lists all files in the current directory with detailed formatting.
- LL: Lists all files, including hidden, in the current directory with detailed formatting.
- SysInfo: Displays detailed system information.
- GetPrivIP: Retrieves the private IP address of the machine.
- GetPubIP: Retrieves the public IP address of the machine (-IncIPv6).
- SpeedTest: Runs a speedtest for your internet.

System Maintenance:
- FlushDNS: Clears the DNS cache.
- SystemScan: Runs a DISM and SFC scan.
- Update: Updates all known apps.
- EmptyBin: Empties the Recycling bin.
- ClearCache: Clears Windows caches.

Utility Functions:
- FE: Opens File Explorer in your current directory.
- WinUtil: Opens the Chris Titus Tech Windows utility.
- ReloadProfile: Reloads the terminal profile.
- ClearRAM: Cleans up the standby memory in RAM.
- ReinstallWinget: Uninstalls Winget and reinstalls it.
- CalcPi: Calculates pi to 100 digits.
- Shutdown: Shutdown PC (-Force to force shutdown).
- RandomFact: Prints a random fun fact.

- CheatSheet: Displays a list of all the most common commands.

Use 'ShowHelp' to display this help message.
"@
}
