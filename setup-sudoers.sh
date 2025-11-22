#!/bin/bash
# Setup passwordless sudo for /etc/hosts modification
# This allows Terraform to run without password prompts

set -e

echo "🔧 Setting up passwordless sudo for /etc/hosts management..."
echo ""

# Get current user
CURRENT_USER=$(whoami)

# Create sudoers file for hosts management
SUDOERS_FILE="/etc/sudoers.d/terraform-hosts"

# Create the sudoers entry
SUDOERS_CONTENT="# Allow ${CURRENT_USER} to modify /etc/hosts without password (for Terraform automation)
${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/bin/sed -i * /etc/hosts
${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/bin/tee -a /etc/hosts
${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/bin/bash -c echo * >> /etc/hosts"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs to be run with sudo to modify sudoers configuration."
    echo ""
    echo "Run: sudo $0"
    echo ""
    echo "Or manually add this to /etc/sudoers.d/terraform-hosts:"
    echo "---"
    echo "$SUDOERS_CONTENT"
    echo "---"
    exit 1
fi

# Create sudoers file
echo "$SUDOERS_CONTENT" > "$SUDOERS_FILE"

# Set proper permissions (required for sudoers files)
chmod 0440 "$SUDOERS_FILE"

# Validate sudoers file
if visudo -c -f "$SUDOERS_FILE"; then
    echo "✅ Sudoers configuration created successfully!"
    echo ""
    echo "File: $SUDOERS_FILE"
    echo ""
    echo "Now you can run: cd terraform && terraform apply -auto-approve"
    echo "Without any password prompts!"
else
    echo "❌ Error: Invalid sudoers configuration"
    rm -f "$SUDOERS_FILE"
    exit 1
fi
