$timeFilePath = [Environment]::GetFolderPath("MyDocuments") + "\PowerShell\LastExecutionTime.txt"
$repo_root = "https://raw.githubusercontent.com/PantiesIsStoopid"

# Define the update interval in days, set to -1 to always check
$updateInterval = 7

# Opt-out of telemetry if PowerShell is running as SYSTEM
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable(
        'POWERSHELL_TELEMETRY_OPTOUT',
        'true',
        [System.EnvironmentVariableTarget]::Machine
    )
}

# Initial GitHub connectivity check with 1 second timeout
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Import Modules and External Profiles
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module $ChocolateyProfile
}

# ---------------------------------------------------------------------------
# Update Profile Function
# ---------------------------------------------------------------------------
function Update-Profile {
    try {
        $url = "$repo_root/PowerShell/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE

        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"

        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "Profile has been updated. Please restart your shell." -ForegroundColor Magenta
        } else {
            Write-Host "Profile is already up to date." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Unable to check for profile updates: $_"
    }
    finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# PowerShell Update Function
# ---------------------------------------------------------------------------
function Update-PowerShell {
    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan

        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')

        if ($currentVersion -lt $latestVersion) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow

            Start-Process powershell.exe `
                -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" `
                -Wait -NoNewWindow

            Write-Host "PowerShell updated. Restart required." -ForegroundColor Magenta
        }
        else {
            Write-Host "PowerShell is up to date." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to update PowerShell: $_"
    }
}

# ---------------------------------------------------------------------------
# Admin Check & Prompt Customization
# ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " }
    else          { "[" + (Get-Location) + "] $ " }
}

$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# ---------------------------------------------------------------------------
# Oh-My-Posh Theme
# ---------------------------------------------------------------------------
$OmpConfig = "$env:TEMP\OneDarkPro.omp.json"
if (-not (Test-Path $OmpConfig)) {
    Invoke-WebRequest "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/OneDarkPro.omp.json" -OutFile $OmpConfig
}

oh-my-posh init pwsh --config $OmpConfig | Invoke-Expression

# ---------------------------------------------------------------------------
# FZF Keybinds and Options
# ---------------------------------------------------------------------------
Set-PSFzfOption -PSReadlineChordReverseHistory "Ctrl+r"

Set-PSReadLineKeyHandler -Chord "Ctrl+f" -ScriptBlock {
    $file = fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'
    if ($file) {
        Set-Location (Split-Path $file)
        nvim $file
    }
}

$ENV:FZF_DEFAULT_OPTS = @"
--color=bg+:#3E4451,bg:#282C34,spinner:#C678DD,hl:#E06C75
--color=fg:#ABB2BF,header:#E06C75,info:#61AFEF,pointer:#C678DD
--color=marker:#98C379,fg+:#ABB2BF,prompt:#61AFEF,hl+:#E06C75
--color=selected-bg:#4B5263
--color=border:#5C6370,label:#ABB2BF
"@

# ---------------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------------
function Touch($File) { "" | Out-File $File -Encoding ASCII }
function Ll        { Get-ChildItem -Force | Format-Table -AutoSize }
function Fe        { Invoke-Item (Get-Location) }
function WinUtil   { Invoke-WebRequest -UseBasicParsing https://christitus.com/win | Invoke-Expression }

# Git Shortcuts
function GL      { git log }
function GS      { git status }
function GA      { git add . }
function GC      { param($m) git commit -m "$m" }
function GP      { git push }
function GCom    { git add .; git commit -m "$args" }
function LazyG   { git add .; git commit -m "$args"; git push }

# ---------------------------------------------------------------------------
# Help Menu
# ---------------------------------------------------------------------------
function ShowHelp {
@"
PowerShell Profile Help
=======================

Directory Navigation:
- Touch <file>          Create a new file in the current directory
- Ll                    List all files (including hidden)
- Fe                    Open Explorer in current directory

Utilities:
- WinUtil               Run Chris Titus Tech WinUtil

Git Shortcuts:
- GL                    git log
- GS                    git status
- GA                    git add .
- GC <msg>              git commit -m "<msg>"
- GP                    git push
- GCom <msg>            add + commit
- LazyG <msg>           add + commit + push

Keybinds:
- Ctrl + F              FZF file picker with preview
- Ctrl + R              FZF command history search

Use ShowHelp to print this menu.
"@
}
