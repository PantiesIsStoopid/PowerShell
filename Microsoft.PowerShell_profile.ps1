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

Invoke-Expression (& { (zoxide init powershell | Out-String) })
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Catppuccin.omp.json" | Invoke-Expression

Set-PSFzfOption -PSReadlineChordProvider "Ctrl+f" -PSReadlineChordReverseHistory "Ctrl+r"

clear 

fastfetch --config "$HOME\Documents\Powershell\FastConfig.jsonc"

# -------------------------------------------------------------------------------------------------------------------------------------------------------

function Touch($file) { "" | Out-File $file -Encoding ASCII }

function La { Get-ChildItem }

function Ll { Get-ChildItem -Path . -Force | Format-Table -AutoSize }

function SpeedTest {  
  Write-Host "Running Speedtest" -ForegroundColor Cyan
  Invoke-RestMethod asheroto.com/speedtest | Invoke-Expression
  Write-Host "Pinging 1.1.1.1" -ForegroundColor Cyan
  ping 1.1.1.1
  Write-Host "Pinging 8.8.8.8" -ForegroundColor Cyan
  ping 8.8.8.8
}

function FlushDNS {
  Clear-DnsClientCache
  Write-Host "DNS has been flushed" -ForegroundColor Green
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
  Write-Host "Restoring permissions completed successfully." -ForegroundColor Green
}

function Update {
  winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
  choco upgrade chocolatey -Y
  choco upgrade all -Y
  Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
  Get-WindowsUpdate
}

function Fe {
  Invoke-Item (Get-Location)
}

function WinUtil {
  Invoke-WebRequest -useb https://christitus.com/win | Invoke-Expression
}

function ReloadProfile {
  & $profile
}

function Shutdown {
  param ([switch]$Force)

  if ($Force) {
    Stop-Computer -Force -Confirm:$false
  }
  else {
    Stop-Computer -Confirm:$false
  }
}

function RPassword {
  param ([Parameter(Mandatory)][int] $length)

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

function GL { git log }

function GS { git status }

function GA { git add . }

function GC { param($m) git commit -m "$m" }

function GP { git push }

function G { __zoxide_z github }

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
