function UpdateProfile
{
  try
  {
    $Url = "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1"
    $TempFile = Join-Path $env:TEMP "Microsoft.PowerShell_profile.ps1"
    $OldHash = Get-FileHash $PROFILE
    Invoke-RestMethod $Url -OutFile $TempFile
    $NewHash = Get-FileHash $TempFile
    if ($NewHash.Hash -ne $OldHash.Hash)
    {
      Copy-Item $TempFile -Destination $PROFILE -Force
      Write-Host "Profile updated. Restart shell to apply changes." -ForegroundColor Magenta
    }
  } catch
  { Write-Verbose "Update failed: $_" 
  } finally
  {
    Remove-Item $TempFile -ErrorAction SilentlyContinue
  }
}

function UpdatePowerShell
{
  try
  {
    $CurrentVersion = $PSVersionTable.PSVersion.ToString()
    $LatestVersion = (Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest").tag_name.Trim('v')
    if ($CurrentVersion -lt $LatestVersion)
    {
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -NoNewWindow
    }
  } catch
  { Write-Verbose "Failed to check PowerShell update: $_" 
  }
}

UpdateProfile
UpdatePowerShell


if (-not (Get-Module -ListAvailable -Name Terminal-Icons))
{
  Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

if (-not (Get-Module -ListAvailable -Name PSReadLine))
{
  Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name PSReadLine 

Invoke-Expression (& { (zoxide init powershell | Out-String) })

$OmpConfig = "$env:TEMP\OneDarkPro.omp.json"
if (-not (Test-Path $OmpConfig))
{
  Invoke-WebRequest "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/OneDarkPro.omp.json" -OutFile $OmpConfig
}
oh-my-posh init pwsh --config $OmpConfig | Invoke-Expression

Set-PSFzfOption -PSReadlineChordReverseHistory "Ctrl+r"

Set-PSReadLineKeyHandler -Chord "Ctrl+f" -ScriptBlock {
  $file = fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'
  if ($file)
  {
    Set-Location (Split-Path $file)
    nvim $file  # change 'code' to 'nvim', 'notepad', etc.
  }
}

$ENV:FZF_DEFAULT_OPTS = @"
--color=bg+:#3E4451,bg:#282C34,spinner:#C678DD,hl:#E06C75
--color=fg:#ABB2BF,header:#E06C75,info:#61AFEF,pointer:#C678DD
--color=marker:#98C379,fg+:#ABB2BF,prompt:#61AFEF,hl+:#E06C75
--color=selected-bg:#4B5263
--color=border:#5C6370,label:#ABB2BF
"@

# -------------------------------------------------------------------------------------------------------------------------------------------------------

function Touch($File)
{ 
  "" | Out-File $File -Encoding ASCII 
}


function Ll
{
  Get-ChildItem -Path . -Force | Format-Table -AutoSize 
}

function Fe
{
  Invoke-Item (Get-Location) 
}

function WinUtil
{
  Invoke-WebRequest -UseBasicParsing https://christitus.com/win | Invoke-Expression 
}

function GL
{
  git log 
}
function GS
{
  git status 
}
function GA
{
  git add . 
}
function GC
{
  param($m) git commit -m "$m" 
}
function GP
{
  git push 
}

function GCom
{
  git add .; git commit -m "$args" 
}

function LazyG
{
  git add .; git commit -m "$args"; git push 
}

#* Help Function
function ShowHelp
{
  @"
PowerShell Profile Help
=======================

Directory Navigation:
- Touch: Create a file in your current directory (FileName.Ext).

File and System Information:
- Ll: Lists all files, including hidden, in the current directory with detailed formatting.

Utility Functions:
- Fe: Opens File Explorer in your current directory.
- WinUtil: Opens the Chris Titus Tech Windows utility.

Git Functions:
- GL: Shortcut for 'git log'.
- GS: Shortcut for 'git status'.
- GA: Shortcut for 'git add.'.
- GC <message>: Shortcut for 'git commit -m' with the specified message.
- GP: Shortcut for 'git push'.
- G: Changes to the GitHub directory.
- GCom <message>: Adds all changes and commits with the specified message.
- LazyG <message>: Adds all changes, commits with the specified message, and pushes to the remote repository.

- Touch: Creates a file in the current directory.
- ShowHelp: Displays this help message.

Keybinds:
- Ctrl + F: Opens fuzzy finder.
- Ctrl + R: Fuzzy find through past command history.
- Ctrl + G: Lets you FZF with preview in your current folder.

Use 'ShowHelp' to display this help message.
"@
}

