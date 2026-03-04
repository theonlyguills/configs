#!/bin/bash

# Safe cleanup script for testing Taskfile
# PRESERVES: SSH keys, Azure CLI login state

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Taskfile Installation Test - Cleanup Phase               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will REMOVE the following to test fresh installation:"
echo "  • Chrome"
echo "  • SDKMAN + Java"
echo "  • Node.js + nvm"
echo "  • IntelliJ IDEA"
echo "  • kubectl, kubectx, kubens, k9s, kubelogin"
echo "  • Homebrew (and all packages installed via brew)"
echo "  • Docker (engine, images, containers, and group membership)"
echo "  • VSCode (Linux version)"
echo ""
echo "This script will PRESERVE:"
echo "  • SSH keys (~/.ssh/)"
echo "  • Azure CLI (and login state)"
echo ""

read -p "Continue with cleanup? (type 'yes' to proceed): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Creating backup metadata..."
mkdir -p /tmp/taskfile-test-backup
date > /tmp/taskfile-test-backup/cleanup-started.txt

# Backup current state
echo "Backing up environment info..."
task verify-setup > /tmp/taskfile-test-backup/before-cleanup.txt 2>&1

echo ""
echo "1️⃣  Removing Chrome..."
if command -v google-chrome &> /dev/null; then
  sudo apt-get remove -y google-chrome-stable 2>&1 | tail -3
  rm -f ~/google-chrome-stable_current_amd64.deb
  echo "   ✅ Chrome removed"
else
  echo "   ⏭️  Chrome not installed"
fi

echo ""
echo "2️⃣  Removing Node.js and nvm..."
if [ -d "$HOME/.nvm" ]; then
  rm -rf ~/.nvm
  # Remove nvm lines from bashrc
  sed -i '/NVM_DIR/d' ~/.bashrc 2>/dev/null || true
  sed -i '/nvm.sh/d' ~/.bashrc 2>/dev/null || true
  echo "   ✅ nvm removed"
else
  echo "   ⏭️  nvm not installed"
fi

echo ""
echo "3️⃣  Removing SDKMAN and Java..."
if [ -d "$HOME/.sdkman" ]; then
  rm -rf ~/.sdkman
  # Remove sdkman lines from bashrc
  sed -i '/SDKMAN/d' ~/.bashrc 2>/dev/null || true
  sed -i '/sdkman-init.sh/d' ~/.bashrc 2>/dev/null || true
  echo "   ✅ SDKMAN removed"
else
  echo "   ⏭️  SDKMAN not installed"
fi

echo ""
echo "4️⃣  Removing IntelliJ IDEA..."
if [ -d ~/idea-IU-* ]; then
  rm -rf ~/idea-IU-*
  rm -f ~/ideaIU-*.tar.gz
  echo "   ✅ IntelliJ removed"
else
  echo "   ⏭️  IntelliJ not installed"
fi

echo ""
echo "5️⃣  Removing VSCode..."
if command -v code &> /dev/null; then
  sudo apt-get remove -y code 2>&1 | tail -3
  sudo rm -f /etc/apt/sources.list.d/vscode.list
  sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg
  # Remove VSCode alias from bashrc
  sed -i '/VSCode for WSL/d' ~/.bashrc 2>/dev/null || true
  sed -i '/alias code=/d' ~/.bashrc 2>/dev/null || true
  echo "   ✅ VSCode removed"
else
  echo "   ⏭️  VSCode not installed"
fi

echo ""
echo "6️⃣  Removing Kubernetes tools..."
# k9s and kubelogin (installed via brew)
if command -v brew &> /dev/null; then
  brew uninstall k9s 2>/dev/null || true
  brew uninstall kubelogin 2>/dev/null || true
  echo "   ✅ k9s and kubelogin removed"
fi

# kubectl, kubectx, kubens (installed via apt)
if command -v kubectl &> /dev/null; then
  sudo apt-get remove -y kubectl kubectx 2>&1 | tail -3
  sudo rm -f /etc/apt/sources.list.d/kubernetes.list
  sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "   ✅ kubectl, kubectx, and kubens removed"
fi

echo ""
echo "7️⃣  Removing Homebrew..."
if command -v brew &> /dev/null; then
  echo "   Uninstalling Homebrew (this may take a minute)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" 2>&1 | tail -5
  # Remove homebrew lines from bashrc
  sed -i '/linuxbrew/d' ~/.bashrc 2>/dev/null || true
  sed -i '/Homebrew/d' ~/.bashrc 2>/dev/null || true
  echo "   ✅ Homebrew removed"
else
  echo "   ⏭️  Homebrew not installed"
fi

echo ""
echo "8️⃣  Removing Docker..."
if command -v docker &> /dev/null; then
  echo "   Stopping Docker containers..."
  docker stop $(docker ps -aq) 2>/dev/null || true
  echo "   Removing Docker packages..."
  sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tail -3
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tail -3
  echo "   Removing Docker data..."
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc
  echo "   Removing user from docker group..."
  sudo deluser $USER docker 2>/dev/null || true
  echo "   ✅ Docker removed (you may need to restart shell for group changes)"
else
  echo "   ⏭️  Docker not installed"
fi

echo ""
echo "9️⃣  Cleaning up temporary files..."
rm -f ~/.wget-hsts

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Cleanup Complete!                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Backup saved to: /tmp/taskfile-test-backup/"
echo ""
echo "Checking what's left..."
task verify-setup

echo ""
echo "You can now test fresh installation with:"
echo "  task setup-all"
