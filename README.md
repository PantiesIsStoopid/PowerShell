# Custom PowerShell Profile

## Installation

Run this in your PowerShell terminal to install the profile:

```powershell
irm "https://github.com/PantiesIsStoopid/PowerShell/raw/main/Setup.ps1" | iex
```

This downloads and runs the setup script which configures aliases, themes, and utility functions.

---

## Functions Documentation

### Update-Profile

Downloads the latest PowerShell profile from GitHub and updates your local profile if there are changes.

### Update-PowerShell

Checks the latest PowerShell version from GitHub and updates your PowerShell using winget if a newer version exists.

### Touch

Creates a new empty file with the specified name.

### Grep

Launches `fzf` fuzzy finder to search files with a preview using `bat`, then opens the selected file.

### Time

Measures and prints the duration it takes to run a given script block.

### La

Lists all files and folders in the current directory.

### Ll

Lists all files and folders, including hidden ones, in a formatted table.

### FlushDNS

Clears the DNS client cache.

### DelCmdHistory

Clears PowerShell command history and removes the history file.

### GetPubIP

Fetches and prints the public IP address.

### GetPrivIP

Prints private IP addresses (IPv4 by default, IPv6 if `-IncIPv6` is set).

### SpeedTest

Runs an internet speed test and pings common public DNS servers.

### Fe

Opens the current directory in File Explorer.

### Update

Updates PowerShell, Chocolatey packages, and runs Windows updates.

### WinUtil

Launches the Chris Titus Tech Windows utility script.

### ReloadProfile

Reloads your PowerShell profile.

### SystemScan

Runs DISM and SFC system file integrity scans, then resets permissions on `C:\`.

### ReinstallWinget

Uninstalls and reinstalls Winget package manager.

### EmptyBin

Empties the Windows Recycle Bin using cleanmgr.

### Shutdown

Shuts down the PC gracefully or forcefully if `-Force` is specified.

### RPassword

Generates a random password of a specified length.

### RandomFact

Fetches and prints a random fun fact from a public API.

### ClearCache

Clears temporary files, system cache, IE cache, and Microsoft Edge cache.

---

## Git Shortcuts

* `GL` — git log
* `GS` — git status
* `GA` — git add .
* `GC <msg>` — git commit -m "<msg>"
* `GP` — git push
* `GCL <url>` — git clone <url>
* `GCom <msg>` — git add ., git commit -m "<msg>"
* `LazyG <msg>` — add, commit, and push
* `LazyInit <url>` — initialize repo, add remote, push

---

## Help and Cheatsheet

* `ShowHelp` — displays help message describing functions and usage
* `CheatSheet` — displays basic PowerShell command cheatsheet
  \`\`

Let me know if you want me to add or tweak anything.
