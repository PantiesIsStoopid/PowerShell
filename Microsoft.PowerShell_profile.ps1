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

if ($global:canConnectToGitHub) {
  Update-Profile
  Update-PowerShell  
}

Import-Module Terminal-Icons
Import-Module -Name PSReadLine 
Import-Module -Name PSFzf

# Initialize Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Initialize Oh My Posh
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Catppuccin.omp.json" | Invoke-Expression

# Initialize Keybinds
Set-PSFzfOption -PSReadlineChordProvider "Ctrl+f" -PSReadlineChordReverseHistory "Ctrl+r"

Set-PSReadLineKeyHandler -Chord Ctrl+g -ScriptBlock { Grep }

$ENV:FZF_DEFAULT_OPTS = @"
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
--color=selected-bg:#45475a
--color=border:#313244,label:#cdd6f4
"@

Clear-Host

# Run Fastfetch (Skip in VSCode)
if ($Env:TERM_PROGRAM -ne "vscode") {
  fastfetch --config "$env:USERPROFILE\Documents\PowerShell\FastConfig.jsonc"
}

#* Alias
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

#* Make a file with a given name and extension
function Touch($file) {
  "" | Out-File $file -Encoding ASCII 
}

#* Let you search and preview files
function Grep {
  $env:BAT_THEME = "Catppuccin Mocha"

  $file = fzf --preview "bat --style=numbers --color=always {}"
  if ($file) { Invoke-Item "$file" }
}

#* Calculate the time taken to run a script block
function Time {
  param([ScriptBlock]$Script)

  $Start = Get-Date
  & $Script
  $End = Get-Date

  $Duration = $End - $Start
  Write-Host "`n⏱️  Duration: $($Duration.ToString())"
}

#* List all files
function La {
  Get-ChildItem
}

#* List all files including hidden
function Ll {
  Get-ChildItem -Path . -Force | Format-Table -AutoSize
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
- ReinstallWinget: Uninstalls Winget and reinstalls it.
- Shutdown: Shutdown PC (-Force to force shutdown).
- RPassword <Length>: Generates a random password of the specified length.
- RandomFact: Prints a random fun fact.

Git Functions:
- GL: Shortcut for 'git log'.
- GS: Shortcut for 'git status'.
- GA: Shortcut for 'git add.'.
- GC <message>: Shortcut for 'git commit -m' with the specified message.
- GP: Shortcut for 'git push'.
- G: Changes to the GitHub directory.
- GCom <message>: Adds all changes and commits with the specified message.
- LazyG <message>: Adds all changes, commits with the specified message, and pushes to the remote repository.
- LazyInit <URL>: Adds all steps for initializing a repo and can add a remote URL.

Additional Functions:
- Grep: Launches an interactive file search using fzf and bat preview. Opens the selected file using the default editor.
- Touch: Creates a file in the current directory.
- ShowHelp: Displays this help message.
- Time <ScriptBlock>: Measures the execution time of a script block.

Keybinds:
- Ctrl + F: Opens fuzzy finder.
- Ctrl + R: Fuzzy find through past command history.
- Ctrl + G: Lets you FZF with preview in your current folder.

CheatSheet: Displays a list of all the most common commands.

Use 'ShowHelp' to display this help message.
"@
}
