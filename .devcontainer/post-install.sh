#!/bin/bash
set -e

sudo apt-get update && sudo apt-get install -y --no-install-recommends iputils-ping iproute2 dnsutils apache2-utils || true
sudo rm -rf /var/lib/apt/lists/*

# Install pre-commit and detect-secrets
echo "Installing pre-commit and detect-secrets..."
pip install --user pre-commit detect-secrets

# Install pre-commit hooks
if [ -f .pre-commit-config.yaml ]; then
  echo "Installing git hooks..."
  pre-commit install
  echo "Pre-commit hooks installed successfully"
else
  echo "Warning: .pre-commit-config.yaml not found, skipping hook installation"
fi
