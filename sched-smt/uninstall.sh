#!/bin/bash
# Uninstall taskmod wrapper and remove its sudoers rule.
#
# Author: https://github.com/marioroy/cachymod
# SPDX-License-Identifier: GPL-2.0

set -e

DEST_BIN="/usr/local/bin/taskmod"
SUDOERS_FILE="/etc/sudoers.d/90-taskmod"

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo ./uninstall.sh)" >&2
    exit 1
fi

echo "Uninstalling taskmod Utility"
echo "=========================================="

if [ -f "$DEST_BIN" ]; then
    rm -f "$DEST_BIN"
    echo "-> Removed $DEST_BIN."
else
    echo "-> $DEST_BIN not found (already removed)."
fi

if [ -f "$SUDOERS_FILE" ]; then
    rm -f "$SUDOERS_FILE"
    echo "-> Removed $SUDOERS_FILE."
else
    echo "-> $SUDOERS_FILE not found (already removed)."
fi

echo "=========================================="
echo "Uninstallation complete!"

