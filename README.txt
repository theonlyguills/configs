CFIS dev-machine bootstrap
==========================

Sets up a Windows + WSL2 (Ubuntu-CFIS) development environment.

Full guide: CFIS-CE wiki > CFIS Developers 2026 > "WSL Tooling Installation".


--------------------------------------------------------------------
1. Install the terminal font  (NON-admin PowerShell)
--------------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

scoop bucket add nerd-fonts
scoop install firacode


--------------------------------------------------------------------
2. Get this repo into your user profile folder
--------------------------------------------------------------------
If you already have git:
    cd $env:USERPROFILE
    git clone https://github.com/theonlyguills/configs

If you don't have git yet, just download bootstrap.ps1 into
C:\Users\<your-profile>\ -- the script installs git and clones this repo
itself if it isn't already present.


--------------------------------------------------------------------
3. Run the bootstrap  (ADMIN PowerShell)
--------------------------------------------------------------------
    cd $env:USERPROFILE\configs
    # Unblock-File -Path .\bootstrap.ps1   # only if you DOWNLOADED the file
    .\bootstrap.ps1

What bootstrap.ps1 does:
  - Installs Git (only if it isn't already installed), WSL2 components,
    and the WezTerm terminal
  - Registers the Ubuntu-CFIS distro
  - Prompts you ONCE, via a Windows credential dialog, for the Ubuntu
    username and password to create -- there is no separate Ubuntu
    first-launch (OOBE) prompt
  - Provisions that user (sudo + systemd) and runs the Linux bootstrap
    synchronously in the same window:
        * Neovim + LazyVim (with build-essential + ripgrep)
        * Taskfile
        * clones this repo into ~/configs
        * shell aliases + a Windows-Edge browser handoff (for az login SSO)
  - Opens WezTerm when it finishes

(For maintainers: set $TestMode = $true at the top of bootstrap.ps1 to run
against a throwaway "CFIS-Claude" distro without touching the real one.)


--------------------------------------------------------------------
4. Install the dev tools  (inside WSL)
--------------------------------------------------------------------
    cd ~/configs
    tl              # list all available tasks
    t setup-all     # install everything (Chrome, Java, Docker, k8s, Node, ...)
    t verify-setup  # check what is installed

See the wiki for SSH keys, cloning the CFIS repos, AKS access, and
per-project setup.
