# Initial GitHub.com connectivity check with 1 second timeout
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

function UpdateProfile {
  try {
    $Url = "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1"
    $TempFile = Join-Path $env:TEMP "Microsoft.PowerShell_profile.ps1"
    $OldHash = Get-FileHash $PROFILE
    Invoke-RestMethod $Url -OutFile $TempFile
    $NewHash = Get-FileHash $TempFile
    if ($NewHash.Hash -ne $OldHash.Hash) {
      Copy-Item $TempFile -Destination $PROFILE -Force
      Write-Host "Profile updated. Restart shell to apply changes." -ForegroundColor Magenta
    }
  }
  catch { Write-Verbose "Update failed: $_" } finally {
    Remove-Item $TempFile -ErrorAction SilentlyContinue
  }
}

function UpdatePowerShell {
  try {
    $CurrentVersion = $PSVersionTable.PSVersion.ToString()
    $LatestVersion = (Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest").tag_name.Trim('v')
    if ($CurrentVersion -lt $LatestVersion) {
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -NoNewWindow
    }
  }
  catch { Write-Verbose "Failed to check PowerShell update: $_" }
}

# Run updates in background (non-blocking)
if ($global:canConnectToGitHub) {
  Start-Job -ScriptBlock { UpdateProfile; UpdatePowerShell } | Out-Null
}


# Import Modules and External Profiles

# Terminal-Icons
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
  Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Chocolatey Profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# PSFzf
if (-not (Get-Module -ListAvailable -Name PSFzf)) {
  Install-Module -Name PSFzf -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name PSFzf

# PSReadLine
if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
  Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module -Name PSReadLine
Invoke-Expression (& { (zoxide init powershell | Out-String) })

$OmpConfig = "$env:TEMP\OneDarkPro.omp.json"
if (-not (Test-Path $OmpConfig)) {
  Invoke-WebRequest "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/OneDarkPro.omp.json" -OutFile $OmpConfig
}

oh-my-posh init pwsh --config $OmpConfig | Invoke-Expression

Set-PSFzfOption -PSReadlineChordProvider "Ctrl+f" -PSReadlineChordReverseHistory "Ctrl+r"

$ENV:FZF_DEFAULT_OPTS = @"
--color=bg+:#3E4451,bg:#282C34,spinner:#C678DD,hl:#E06C75
--color=fg:#ABB2BF,header:#E06C75,info:#61AFEF,pointer:#C678DD
--color=marker:#98C379,fg+:#ABB2BF,prompt:#61AFEF,hl+:#E06C75
--color=selected-bg:#4B5263
--color=border:#5C6370,label:#ABB2BF
"@

# Keep fastfetch, but don’t clear screen
fastfetch --config "$HOME\Documents\Powershell\FastConfig.jsonc"

# -------------------------------------------------------------------------------------------------------------------------------------------------------

function Touch($File) { 
  "" | Out-File $File -Encoding ASCII 
}

function Time {
  param([ScriptBlock]$Script)
  $Start = Get-Date
  & $Script
  $End = Get-Date
  $Duration = $End - $Start
  Write-Host "`n⏱️  Duration: $($Duration.ToString())"
}

function Ll {
  Get-ChildItem -Path . -Force | Format-Table -AutoSize 
}

function SpeedTest {
  Write-Host "Running Speedtest" -ForegroundColor Cyan
  Invoke-RestMethod asheroto.com/speedtest | Invoke-Expression
  Write-Host "Pinging 1.1.1.1" -ForegroundColor Cyan
  ping 1.1.1.1
}

function SystemScan {
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
  Write-Host "Restoring permissions completed successfully" -ForegroundColor Green
}

function Fe {
  Invoke-Item (Get-Location) 
}

function WinUtil {
  Invoke-WebRequest -UseBasicParsing https://christitus.com/win | Invoke-Expression 
}

function RPassword {
  param ([Parameter(Mandatory)][int] $Length)
  $CharSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
  $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $Bytes = New-Object byte[]($Length)
  $Rng.GetBytes($Bytes)
  $Result = New-Object char[]($Length)
  for ($i = 0; $i -lt $Length; $i++) {
    $Result[$i] = $CharSet[$Bytes[$i] % $CharSet.Length] 
  }
  return (-join $Result)
}

function GL {
  git log 
}
function GS {
  git status 
}
function GA {
  git add . 
}
function GC {
  param($m) git commit -m "$m" 
}
function GP {
  git push 
}

function GCom {
  git add .; git commit -m "$args" 
}

function LazyG {
  git add .; git commit -m "$args"; git push 
}

#* Help Function
function ShowHelp {
  @"
PowerShell Profile Help
=======================

Directory Navigation:
- Touch: Create a file in your current directory (FileName.Ext).

File and System Information:
- La: Lists all files in the current directory with detailed formatting.
- Ll: Lists all files, including hidden, in the current directory with detailed formatting.
- SpeedTest: Runs a speedtest for your internet.

System Maintenance:
- FlushDNS: Clears the DNS cache.
- SystemScan: Runs a DISM and SFC scan.
- Update: Updates all known apps.

Utility Functions:
- Fe: Opens File Explorer in your current directory.
- WinUtil: Opens the Chris Titus Tech Windows utility.
- ReloadProfile: Reloads the terminal profile.
- Shutdown: Shutdown PC (-Force to force shutdown).
- RPassword <Length>: Generates a random password of the specified length.

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

