#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/containers/systemd"
ROOT_SCRIPT_DIR="$SCRIPT_DIR/root"
ROOT_TARGET_DIR="/etc/containers/systemd"
REPO_DIR="${HOME}/home-server-configs"

echo "Setting up Podman quadlets..."

mkdir -p "$TARGET_DIR"

for file in "$SCRIPT_DIR"/*.container "$SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/$basename_file"
        echo "Linked $basename_file"
    fi
done

echo ""
echo "Installing root Quadlets to $ROOT_TARGET_DIR..."
sudo mkdir -p "$ROOT_TARGET_DIR"

for file in "$ROOT_SCRIPT_DIR"/*.container "$ROOT_SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        sudo ln -sf "$file" "$ROOT_TARGET_DIR/$basename_file"
        echo "Linked root $basename_file"
    fi
done

# These services moved from the user manager to the system manager.
for file in "$ROOT_SCRIPT_DIR"/*.container "$ROOT_SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        if [ -L "$TARGET_DIR/$basename_file" ]; then
            rm "$TARGET_DIR/$basename_file"
            echo "Removed user-level $basename_file"
        fi
    fi
done

echo ""
echo "Quadlets installed to $TARGET_DIR"
echo "Root Quadlets installed to $ROOT_TARGET_DIR"
echo ""
echo "Config directories (must exist):"
echo "  $HOME/service-data/etc-pihole"
echo "  $REPO_DIR/data/n8n-data"
echo "  $HOME/service-data/ha-config"
echo "  $HOME/service-data/matter-server"
echo "  $HOME/service-data/otbr"
echo ""

echo "Reloading systemd daemon..."
systemctl --user daemon-reload
sudo systemctl daemon-reload

echo ""
echo "Available services:"
ls -1 "$TARGET_DIR"/*.container "$TARGET_DIR"/*.pod 2>/dev/null | xargs -n1 basename | sort
