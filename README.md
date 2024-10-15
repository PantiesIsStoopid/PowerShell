# PowerShell Profile Automation Script

## Overview

This PowerShell script automates various system management tasks, making it easier for IT administrators, developers, or anyone looking to streamline system setup and maintenance. It includes a variety of functions for managing files, directories, system information, and more.

## Features

### Directory Navigation

- **Touch**: Create a file in your current directory (FileName.Ext).
- **Docs**: Navigate to the user's Documents folder.
- **Dtop**: Navigate to the user's Desktop folder.
- **DLoads**: Navigate to the user's Downloads folder.
- **Home**: Go to the user's home directory.
- **Root**: Go to the C: drive.

### File and System Information

- **LA**: List all files in the current directory with detailed formatting.
- **LL**: List all files, including hidden ones, in the current directory.
- **SysInfo**: Display detailed system information.
- **GetPrivIP**: Retrieve the private IP address of the machine.
- **GetPubIP**: Retrieve the public IP address of the machine (includes IPv6).
- **SpeedTest**: Run a speed test for your internet connection.

### System Maintenance

- **FlushDNS**: Clear the DNS cache.
- **SystemScan**: Run a DISM and SFC scan.
- **Update**: Update all known apps.
- **EmptyBin**: Empty the Recycle Bin.
- **ClearCache**: Clear Windows caches.

### Utility Functions

- **FE**: Open File Explorer in the current directory.
- **Winutil**: Open the Chris Titus Tech Windows utility.
- **ReloadProfile**: Reload the terminal profile.
- **ClearRAM**: Clean up standby memory in RAM.
- **ReinstallWinget**: Uninstall and reinstall Winget.
- **CalcPi**: Calculate pi to 100 digits.
- **Shutdown**: Shutdown the PC (-Force to force shutdown).
- **RandomFact**: Print a random fun fact.
- **RPassword**: Makes a random password (Integer to adjust length)
- **CheatSheet**: Display a list of common commands.

### Git Function

- **GS**: Shortcut for 'git status'.
- **GA** - Shortcut for 'git add .'.
- **GC** (message) - Shortcut for 'git commit -m'.
- **GP** - Shortcut for 'git push'.
- **G** - Changes to the GitHub directory.
- **GCom** (message) - Adds all changes and commits with the specified message.
- **LazyG** (message) - Adds all changes, commits with the specified message, and pushes to the remote repository.

### Installation Function

Use the following function to easily install everything needed for the script. The default font in the terminal must be manually set to "Cascadia Cove NF."

```powershell
irm "https://raw.githubusercontent.com/PantiesIsStoopid/PowershellProfile/refs/heads/master/Setup.ps1" | iex
