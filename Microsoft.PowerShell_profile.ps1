# Opt-out of telemetry (only if running as admin)
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
  [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Check GitHub connectivity (1s timeout)
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Update PowerShell Profile
function Update-Profile {
  try {
    $Url = "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1"
    $oldhash = Get-FileHash $PROFILE
    Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
    $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
    if ($newhash.Hash -ne $oldhash.Hash) {
      Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
      Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    }
    else {
      Write-Host "Profile is up to date." -ForegroundColor Green
    }
  }
  catch {
    Write-Error "Unable to check for `$profile updates: $_"
  }
  finally {
    Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
  }
}

# Update PowerShell
function Update-PowerShell {
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
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
      Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    }
    else {
      Write-Host "Your PowerShell is up to date." -ForegroundColor Green
    }
  }
  catch {
    Write-Error "Failed to update PowerShell. Error: $_"
  }
}
Update-PowerShell

# Initialize Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Initialize Oh My Posh
if (-not ($PSCmdlet.MyInvocation.PSCommandPath -match 'oh-my-posh')) {
  oh-my-posh init pwsh --config "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/DraculaGit.omp.json" | Invoke-Expression
}

# Install and Import Modules Efficiently
$modules = @("Terminal-Icons", "PSReadLine", "PSFzf")

# Import modules
$modules | ForEach-Object { 
  try {
    Import-Module -Name $_ -ErrorAction Stop
  }
  catch { Write-Error "Failed to import module" }
}

Set-PSFzfOption -PSReadlineChordProvider "Ctrl+f" -PSReadlineChordReverseHistory "Ctrl+r"

# Run Fastfetch (Skip in VSCode)
if ($Env:TERM_PROGRAM -ne "vscode") {
  fastfetch --config "$env:USERPROFILE\Documents\PowerShell\FastConfig.jsonc"
}

#* Alias
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function Vim {
  nvim
}

function Touch($file) {
  "" | Out-File $file -Encoding ASCII 
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
function La {
  Get-ChildItem
}

#* List all files including hidden
function Ll {
  Get-ChildItem -Path . -Force | Format-Table -AutoSize
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

#* Delete Command History
function DelCmdHistory {
  Clear-History
  Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\*" -Recurse -Force
  Write-Host "Command history has been cleared" -ForegroundColor Green
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
function SpeedTest {  
  Write-Host "Running Speedtest" -ForegroundColor Cyan
  Invoke-RestMethod asheroto.com/speedtest | Invoke-Expression
  Write-Host "Pinging 1.1.1.1" -ForegroundColor Cyan
  ping 1.1.1.1
  Write-Host "Pinging 8.8.8.8" -ForegroundColor Cyan
  ping 8.8.8.8
}

#* Open current directory in File Explorer
function Fe {
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
  choco upgrade chocolatey -Y
  choco upgrade all -Y

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
  }
  catch {
    Write-Host "DISM scan failed: $_" -ForegroundColor Red
  }

  # Run SFC scan
  Write-Host "Starting SFC scan..." -ForegroundColor Cyan
  try {
    sfc /scannow
    Write-Host "SFC scan completed successfully." -ForegroundColor Green
  }
  catch {
    Write-Host "SFC scan failed: $_" -ForegroundColor Red
  }

  Write-Host "Restoring original file permissions" -ForegroundColor Cyan
  icacls "C:\" /reset /t /c /l
  Write-Host "Restoring permissions completed successfully." -ForegroundColor Green
}

#* Function to clear system memory (not specifically standby RAM)
function ClearRAM {
  # Define URL and paths
  $Url = "https://download.sysinternals.com/files/RAMMap.zip"
  $zipPath = "C:\RAMMap.zip"
  $extractPath = "C:\RAMMap"

  # Download RAMMap
  Invoke-WebRequest -Uri $Url -OutFile $zipPath

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
  }
  else {
    # Gracefully shut down the PC
    Stop-Computer -Confirm:$false
  }
}

#* RandomPassword
function RPassword {
  param (
    [Parameter(Mandatory)]
    [int] $length
  )

  #$charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{]+-[*=@:)}$^%;(_!&amp;#?>/|.'.ToCharArray()
  $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()

  $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $bytes = New-Object byte[]($length)

  $rng.GetBytes($bytes)

  $result = New-Object char[]($length)

  for ($i = 0 ; $i -lt $length ; $i++) {
    $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
  }

  return (-join $result)
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
  RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8
  Write-Host "Internet Explorer cache cleared." -ForegroundColor Green

  # Clear Microsoft Edge Cache
  Write-Host "Clearing Microsoft Edge cache..." -ForegroundColor Cyan
  $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
  Remove-Item -Path $edgeCachePath* -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Microsoft Edge cache cleared." -ForegroundColor Green
}

# Git Shortcuts
function GL { git log }

function GS { git status }

function GA { git add . }

function GC { param($m) git commit -m "$m" }

function GP { git push }

function G { __zoxide_z github }

function GCL { git clone "$args" }

function GCom {
  git add .
  git commit -m "$args"
}

function LazyG {
  git add .
  git commit -m "$args"
  git push
}

function LazyInit {
  git init
  git add .
  git commit -m "first commit"
  git branch -M master
  git remote add origin $args
  git push -u origin master
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

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
- La: Lists all files in the current directory with detailed formatting.
- Ll: Lists all files, including hidden, in the current directory with detailed formatting.
- SysInfo: Displays detailed system information.
- GetPrivIP: Retrieves the private IP address of the machine.
- GetPubIP (-IncIPv6): Retrieves the public IP address of the machine (-IncIPv6).
- SpeedTest: Runs a speedtest for your internet.

System Maintenance:
- FlushDNS: Clears the DNS cache.
- DelCmdHistory: Deletes the command history.

- SystemScan: Runs a DISM and SFC scan.
- Update: Updates all known apps.
- EmptyBin: Empties the Recycling bin.
- ClearCache: Clears Windows caches.

Utility Functions:
- Fe: Opens File Explorer in your current directory.
- WinUtil: Opens the Chris Titus Tech Windows utility.
- ReloadProfile: Reloads the terminal profile.
- ClearRAM: Cleans up the standby memory in RAM.
- ReinstallWinget: Uninstalls Winget and reinstalls it.
- CalcPi: Calculates pi to 100 digits.
- Shutdown: Shutdown PC (-Force to force shutdown).
- RPassword <Length>: Makes a random password.
- RandomFact: Prints a random fun fact.

Git Function:
- GL: Shortcut for 'git log'.
- GS: Shortcut for 'git status'.
- GA - Shortcut for 'git add .'.
- GC <message> - Shortcut for 'git commit -m'.
- GP - Shortcut for 'git push'.
- G - Changes to the GitHub directory.
- GCom <message> - Adds all changes and commits with the specified message.
- LazyG <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.
- LazyInit <URL> - Adds all steps for the init of a repo and can add remote url.

- CheatSheet: Displays a list of all the most common commands.

Use 'ShowHelp' to display this help message.
"@
}
