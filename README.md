# PowerShell Profile Setup Documentation

This guide explains the features and usage of a custom PowerShell profile designed to improve system navigation, information gathering, maintenance, and Git management. The profile includes multiple aliases for various tasks, along with system utilities and Git functions.

## Installation

To install this custom PowerShell profile, run the following command in your PowerShell terminal:

```powershell
irm "https://github.com/PantiesIsStoopid/PowerShell/raw/main/Setup.ps1" | iex
```

This command will download and execute the PowerShell script that sets up your profile, including aliases, themes, and utility functions.

## Directory Navigation Aliases

These aliases provide shortcuts for commonly used directories:

- **Touch**: Creates a file in your current directory (`Touch FileName.txt`).
- **Docs**: Changes the directory to your user’s Documents folder.
- **Dtop**: Changes the directory to your user’s Desktop folder.
- **DLoads**: Changes the directory to your user’s Downloads folder.
- **Home**: Changes the directory to your user’s home folder.
- **Root**: Changes the directory to the C: drive.

## File and System Information Aliases

These aliases help retrieve system information and manage files:

- **La**: Lists all files in the current directory with detailed formatting.
- **Ll**: Lists all files, including hidden files, in the current directory with detailed formatting.
- **SysInfo**: Displays detailed system information (CPU, memory, OS version, etc.).
- **GetPrivIP**: Retrieves the private IP address of your machine.
- **GetPubIP**: Retrieves the public IP address of your machine.
  - Add `-IncIPv6` to include the IPv6 address as well.
- **SpeedTest**: Runs a speed test for your internet connection.

## System Maintenance Aliases

These aliases assist with routine maintenance tasks:

- **FlushDNS**: Clears the DNS cache to resolve DNS-related issues.
- **DelCmdHistory**: Deletes all history of commands done in PowerShell.
- **SystemScan**: Runs a DISM and SFC scan to repair system files and the Windows image.
- **Update**: Updates all known applications on your system.
- **EmptyBin**: Empties the Recycling Bin.
- **ClearCache**: Clears Windows system caches to free up disk space.

## Utility Functions

These functions help with file management and system utilities:

- **Fe**: Opens File Explorer in your current directory.
- **WinUtil**: Opens the Chris Titus Tech Windows utility.
- **ReloadProfile**: Reloads your PowerShell profile to apply any changes.
- **ReinstallWinget**: Uninstalls Winget and reinstalls it for better package management.
- **Shutdown**: Shutdown your PC. Add `-Force` to force shutdown.
- **RPassword <Length>**: Generates a random password of specified length.
- **RandomFact**: Prints a random fun fact.

## Git Management Aliases

These aliases simplify Git commands for your workflow:

- **GL**: Shortcut for `git log`.
- **GS**: Shortcut for `git status`.
- **GA**: Shortcut for `git add .`.
- **GC <message>**: Shortcut for `git commit -m "message"`.
- **GP**: Shortcut for `git push`.
- **G**: Changes to your GitHub directory.
- **GCom <message>**: Adds all changes and commits with a specified message.
- **LazyG <message>**: Adds all changes, commits with a message, and pushes to the remote repository.
- **LazyInit <URL>**: Initializes a Git repository, adds all files, commits, and sets the remote URL.

## Keybinds

- **Ctrl + F**: opens fuzzy finder
- **Ctrl + R**: fuzzy find through past command history
- **Ctrl + G**: lets you grep in your current folder

## CheatSheet

Use the **CheatSheet** alias to display a list of all the most common commands in this PowerShell profile.

## Custom Oh-My-Posh Theme & FastFetch Theme

The profile is pre-configured with a custom **Oh-My-Posh** theme to enhance the appearance of the PowerShell terminal, along with a **FastFetch** theme to provide efficient system stats and directory information.

## Opt-Out of Telemetry

The setup script ensures that any telemetry or data collection services are opted out to enhance privacy.

## Easy Install Script

This setup can be installed effortlessly via the following one-liner:

```powershell
irm "https://github.com/PantiesIsStoopid/PowerShell/raw/main/Setup.ps1" | iex
```

```

Let me know if you'd like any changes!
```
