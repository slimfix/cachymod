#!/bin/bash
# Install taskmod wrapper and configure passwordless sudoers rule.
#
# Author: https://github.com/marioroy/cachymod
# SPDX-License-Identifier: GPL-2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_BIN="$SCRIPT_DIR/taskmod"
DEST_BIN="/usr/local/bin/taskmod"
SUDOERS_FILE="/etc/sudoers.d/90-taskmod"

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo ./install.sh)" >&2
    exit 1
fi

if [ ! -f "$SRC_BIN" ]; then
    echo "Error: $SRC_BIN not found." >&2
    exit 1
fi

echo "Installing taskmod Utility"
echo "=========================================="

echo "-> Installing script to $DEST_BIN..."
install -m 0755 "$SRC_BIN" "$DEST_BIN"
echo "   Success: Installed $DEST_BIN."

echo "-> Deploying sudoers configuration to $SUDOERS_FILE..."
TMP_SUDOERS="$(mktemp)"
cat << 'EOF' > "$TMP_SUDOERS"
# Allow wheel group to toggle CachyMod scheduler features without a password
%wheel ALL=(root) NOPASSWD: \
  /usr/bin/sysctl kernel.sched_idlecore_enabled=0, \
  /usr/bin/sysctl kernel.sched_idlecore_enabled=1, \
  /usr/bin/sysctl kernel.sched_relax_asym_enabled=0, \
  /usr/bin/sysctl kernel.sched_relax_asym_enabled=1
EOF

chmod 0440 "$TMP_SUDOERS"

echo "-> Verifying sudoers configuration syntax..."
if visudo -cf "$TMP_SUDOERS" >/dev/null 2>&1; then
    mv "$TMP_SUDOERS" "$SUDOERS_FILE"
    chown root:root "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    echo "   Success: Configuration deployed and validated."
else
    rm -f "$TMP_SUDOERS"
    echo "   Error: Sudoers syntax validation failed. Aborting." >&2
    exit 1
fi

echo "=========================================="
echo "Installation complete!"

