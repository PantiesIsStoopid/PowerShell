# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Install PowerShell 7 and Set as Default
$Pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
$ShortcutPath = "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\PowerShell 7.lnk"

# Check if PowerShell 7 is already installed
if (-Not (Test-Path $Pwsh7Path)) {
  Write-Host "Installing PowerShell 7..."
  Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.3.7-win-x64.msi" -OutFile "$Env:TEMP\pwsh7.msi"
  Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$Env:TEMP\pwsh7.msi`" /quiet /norestart" -Wait
  Write-Host "PowerShell 7 installed successfully."
} else {
  Write-Host "PowerShell 7 is already installed."
}

# Check if the shortcut exists
if (Test-Path $ShortcutPath) {
  Write-Host "Setting PowerShell 7 as the default terminal..."
  
  # Update the default terminal setting
  $TerminalSettingsPath = "$Env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  $Settings = Get-Content -Path $TerminalSettingsPath -Raw | ConvertFrom-Json
  $Profile = $Settings.profiles.list | Where-Object { $_.name -eq "PowerShell" }
  if ($Profile -and $Profile.commandline -ne $Pwsh7Path) {
    $Profile.commandline = $Pwsh7Path
    $Settings.profiles.list = $Settings.profiles.list | Where-Object { $_.name -ne "PowerShell" } + $Profile
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $TerminalSettingsPath
    Write-Host "Default terminal updated to PowerShell 7."
  } else {
    Write-Host "Default terminal is already set to PowerShell 7."
  }
} else {
  Write-Host "PowerShell 7 shortcut not found. Install might not have created it."
}


# Function to install Nerd Fonts
function Install-NerdFonts {
    param (
        [string]$FontName = "FiraCode",
        [string]$FontDisplayName = "Fira Code NF",
        [string]$Version = "3.2.1"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            Write-Host "Downloading font ${FontDisplayName}..."
            $webClient.DownloadFile((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            if (Test-Path $zipFilePath) {
                Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
                $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
                Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                    If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                        $destination.CopyHere($_.FullName, 0x10)
                    }
                }

                Remove-Item -Path $extractPath -Recurse -Force
                Remove-Item -Path $zipFilePath -Force
                Write-Host "Font ${FontDisplayName} installed successfully"
            } else {
                Write-Error "Failed to download ${FontDisplayName} font."
            }
        } else {
            Write-Host "Font ${FontDisplayName} already installed"
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}


# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# FastFetch Config Install

# Download and move FastConfig.jsonc to the same directory as the PowerShell profile
try {
  $configUrl = "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/FastConfig.jsonc"
  $configDest = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "FastConfig.jsonc"
  Invoke-RestMethod -Uri $configUrl -OutFile $configDest
  Write-Host "FastConfig.jsonc downloaded to $configDest"
} catch {
  Write-Error "Failed to download or move FastConfig.jsonc. Error: $_"
}












# OMP Install
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"

# Final check and message to the user
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF")) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
} else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}

# Choco install
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}
# zoxide Install
try {
    winget install -e --id ajeetdsouza.zoxide
    Write-Host "zoxide installed successfully."
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}
try {
    winget install fastfetch
    Write-Host "fastfetch installed successfully."
}
catch {
    Write-Error "Failed to install fastfetch. Error: $_"
}

# Ask the user if they want to install Yazi
$installYazi = Read-Host "Do you want to install Yazi? (Y/N)"

if ($installYazi -eq 'Y' -or $installYazi -eq 'y') {
    try {
        # Install Yazi
        winget install sxyazi.yazi
        # Install the optional dependencies (recommended)
        winget install 7zip.7zip jqlang.jq sharkdp.fd BurntSushi.ripgrep.MSVC junegunn.fzf ajeetdsouza.zoxide ImageMagick.ImageMagick
    } catch {
        Write-Error "Failed to install Yazi. Error: $_"
    }
} else {
    Write-Host "Installation aborted."
}
