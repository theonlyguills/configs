#!/bin/bash
# Script to add bootstrap auto-run to .bashrc

if ! grep -q "BOOTSTRAP_AUTO_RUN" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# BOOTSTRAP_AUTO_RUN - This will be removed automatically
if [ -f ~/bootstrap.sh ]; then
    echo ""
    echo "==========================================="
    echo "Running CFIS development environment setup..."
    echo "==========================================="
    echo ""
    ~/bootstrap.sh
fi
EOF
    echo "Added to .bashrc"
else
    echo "Already in .bashrc"
fi
