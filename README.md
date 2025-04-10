windows
for windows setup with my preferred
1. apps
2. drivers
3. wallpapers

Steps
1. Search for Powershell by clicking on Search or pressing the windows key and putting in powershell and find the option to open in administrator (will prompt you for confirmation, press confirm/yes)
2. Open Powershell in Adminstrator
3. Ensure you have an internet connection
4. Select a script - recommended to follow the order below
5. Paste it into the powershell window that you opened earlier (THE SCRIPT WILL NOT WORK, IT WILL JUST CLOSE **IF** YOU ARE USING A NON-ADMINISTRATOR/NON-PRIVILEGED POWERSHELL SESSION)

usage: (in preferrable/best order)


preliminary.ps1: (first)

```irm https://raw.githubusercontent.com/sneepzity/windows/refs/heads/main/preliminary.ps1 | iex```

installapps.ps1: (second)

```irm https://raw.githubusercontent.com/sneepzity/windows/refs/heads/main/installapps.ps1 | iex```


otherinstalls.ps1: (third)

```irm https://raw.githubusercontent.com/sneepzity/windows/refs/heads/main/otherinstalls.ps1 | iex```

chocolatey-dev.ps1: (fourth)

```irm https://raw.githubusercontent.com/sneepzity/windows/refs/heads/main/chocolatey-dev.ps1 | iex```

extra.ps1 (optional)

```irm https://raw.githubusercontent.com/sneepzity/windows/refs/heads/main/extra.ps1 | iex```
