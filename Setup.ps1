# Ensure the script can run with elevated privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "Please run this script as an Administrator!"
  Break
}

# Function to test internet connectivity
Function TestInternetConnection {
  Try {
    $TestConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
    Return $true
  }
  Catch {
    Write-Warning "Internet connection is required but not available. Please check your connection."
    Return $false
  }
}

# Install PowerShell 7 and Set as Default
$Pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
$ShortcutPath = "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\PowerShell 7.lnk"

# Check if PowerShell 7 is already installed
If (-Not (Test-Path $Pwsh7Path)) {
  Write-Host "Installing PowerShell 7..."
  Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.3.7-win-x64.msi" -OutFile "$Env:TEMP\pwsh7.msi"
  Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$Env:TEMP\pwsh7.msi`" /quiet /norestart" -Wait
  Write-Host "PowerShell 7 installed successfully."
}
Else {
  Write-Host "PowerShell 7 is already installed."
}

# Check if the shortcut exists
If (Test-Path $ShortcutPath) {
  Write-Host "Setting PowerShell 7 as the default terminal..."
  
  # Update the default terminal setting
  $TerminalSettingsPath = "$Env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  $Settings = Get-Content -Path $TerminalSettingsPath -Raw | ConvertFrom-Json
  $Profile = $Settings.profiles.list | Where-Object { $_.name -eq "PowerShell" }
  If ($Profile -and $Profile.commandline -ne $Pwsh7Path) {
    $Profile.commandline = $Pwsh7Path
    $Settings.profiles.list = $Settings.profiles.list | Where-Object { $_.name -ne "PowerShell" } + $Profile
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $TerminalSettingsPath
    Write-Host "Default terminal updated to PowerShell 7."
  }
  Else {
    Write-Host "Default terminal is already set to PowerShell 7."
  }
}
Else {
  Write-Host "PowerShell 7 shortcut not found. Install might not have created it."
}

# Function to install Nerd Fonts
Function InstallNerdFonts {
  Param (
    [string]$FontName = "FiraCode",
    [string]$FontDisplayName = "Fira Code NF",
    [string]$Version = "3.2.1"
  )

  Try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $FontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
    If ($FontFamilies -notcontains "${FontDisplayName}") {
      $FontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
      $ZipFilePath = "$env:TEMP\${FontName}.zip"
      $ExtractPath = "$env:TEMP\${FontName}"

      $WebClient = New-Object System.Net.WebClient
      Write-Host "Downloading font ${FontDisplayName}..."
      $WebClient.DownloadFile((New-Object System.Uri($FontZipUrl)), $ZipFilePath)

      If (Test-Path $ZipFilePath) {
        Expand-Archive -Path $ZipFilePath -DestinationPath $ExtractPath -Force
        $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $ExtractPath -Recurse -Filter "*.ttf" | ForEach-Object {
          If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
            $Destination.CopyHere($_.FullName, 0x10)
          }
        }

        Remove-Item -Path $ExtractPath -Recurse -Force
        Remove-Item -Path $ZipFilePath -Force
        Write-Host "Font ${FontDisplayName} installed successfully"
      }
      Else {
        Write-Error "Failed to download ${FontDisplayName} font."
      }
    }
    Else {
      Write-Host "Font ${FontDisplayName} already installed"
    }
  }
  Catch {
    Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
  }
}

# Check for internet connectivity before proceeding
If (-not (TestInternetConnection)) {
  Break
}

# Profile creation or update
If (!(Test-Path -Path $PROFILE -PathType Leaf)) {
  Try {
    # Detect Version of PowerShell & Create Profile directories if they do not exist.
    $ProfilePath = ""
    If ($PSVersionTable.PSEdition -eq "Core") {
      $ProfilePath = "$env:userprofile\Documents\Powershell"
    }
    ElseIf ($PSVersionTable.PSEdition -eq "Desktop") {
      $ProfilePath = "$env:userprofile\Documents\WindowsPowerShell"
    }

    If (!(Test-Path -Path $ProfilePath)) {
      New-Item -Path $ProfilePath -ItemType "directory"
    }

    Invoke-RestMethod https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
    Write-Host "The profile @ [$PROFILE] has been created."
    Write-Host "If you want to make any personal changes or customizations, please do so at [$ProfilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
  }
  Catch {
    Write-Error "Failed to create or update the profile. Error: $_"
  }
}
Else {
  Try {
    Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
    Invoke-RestMethod https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
    Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
    Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
  }
  Catch {
    Write-Error "Failed to backup and update the profile. Error: $_"
  }
}

# FastFetch Config Install

# Download and move FastConfig.jsonc to the same directory as the PowerShell profile
Try {
  $ConfigUrl = "https://raw.githubusercontent.com/PantiesIsStoopid/PowerShell/refs/heads/main/FastConfig.jsonc"
  $ConfigDest = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "FastConfig.jsonc"
  Invoke-RestMethod -Uri $ConfigUrl -OutFile $ConfigDest
  Write-Host "FastConfig.jsonc downloaded to $ConfigDest"
}
Catch {
  Write-Error "Failed to download or move FastConfig.jsonc. Error: $_"
}

# OMP Install
Try {
  winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
Catch {
  Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
InstallNerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"

# Final check and message to the user
If ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($FontFamilies -contains "CaskaydiaCove NF")) {
  Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
}
Else {
  Write-Warning "Setup completed with errors. Please check the error messages above."
}

# Choco install
Try {
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
Catch {
  Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
Try {
  Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
Catch {
  Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# PSReadLine Install
Try {
  Install-Module PSReadLine -Force
  
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
}
Catch {
  Write-Error "Failed to install PSReadLine module. Error: $_"
}

# PSFzf Install
Try {
  Install-Module PSFzf -Force
}
Catch {
  Write-Error "Failed to install PSReadLine module. Error: $_"
}

# Zoxide Install
Try {
  winget install -e --id ajeetdsouza.zoxide
  Write-Host "zoxide installed successfully."
}
Catch {
  Write-Error "Failed to install zoxide. Error: $_"
}

Try {
  winget install fastfetch
  Write-Host "fastfetch installed successfully."
}
Catch {
  Write-Error "Failed to install fastfetch. Error: $_"
}

Try {
  winget install junegunn.fzf
  Write-Host "fzf installed successfully."
}
Catch {
  Write-Error "Failed to install fzf. Error: $_"
}

Try {
  # Install bat using Chocolatey
  choco install bat -y

  # Get bat config directory
  $BatConfigDir = (bat --config-dir | Out-String).Trim()

  $ThemeDir = Join-Path $BatConfigDir "themes"

  # Ensure the themes directory exists
  New-Item -ItemType Directory -Path $ThemeDir -Force

  # Download themes
  Invoke-WebRequest -Uri "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Latte.tmTheme" -OutFile "$ThemeDir\Catppuccin Latte.tmTheme"
  Invoke-WebRequest -Uri "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Frappe.tmTheme" -OutFile "$ThemeDir\Catppuccin Frappe.tmTheme"
  Invoke-WebRequest -Uri "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme" -OutFile "$ThemeDir\Catppuccin Macchiato.tmTheme"
  Invoke-WebRequest -Uri "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme" -OutFile "$ThemeDir\Catppuccin Mocha.tmTheme"

  # Rebuild bat cache
  bat cache --build

  Write-Host "bat installed and themes applied successfully." -ForegroundColor Green
}
Catch {
  Write-Error "Failed to install bat. Error: $_"
}

# Ask the user if they want to install Yazi
$InstallYazi = Read-Host "Do you want to install Yazi? (Y/N)"

If ($InstallYazi -eq 'Y' -or $InstallYazi -eq 'y') {
  Try {
    # Install Yazi
    winget install sxyazi.yazi
    # Install the optional dependencies (recommended)
    winget install 7zip.7zip jqlang.jq sharkdp.fd BurntSushi.ripgrepMSVC junegunn.fzf ajeetdsouza.zoxide ImageMagick.ImageMagick
  }
  Catch {
    Write-Error "Failed to install Yazi. Error: $_"
  }
}
Else {
  Write-Host "Installation aborted."
}

# Ask the user if they want to install Catppuccin Theme
$InstallCatppuccin = Read-Host "Do you want to install Catppuccin Theme? (Y/N)"

If ($InstallCatppuccin -eq 'Y' -or $InstallCatppuccin -eq 'y') {
  Try {
    # Install Catppuccin theme
    Start-Process "https://github.com/catppuccin/windows-terminal"
  }
  Catch {
    Write-Error "Failed to install Catppuccin Theme."
  }
}
Else {
  Write-Host "Installation aborted."
}

exit