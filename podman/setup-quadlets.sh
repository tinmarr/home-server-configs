#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/containers/systemd"
REPO_DIR="${HOME}/home-server-configs"

echo "Setting up rootless Podman quadlets..."

mkdir -p "$TARGET_DIR"

for file in "$SCRIPT_DIR"/*.container "$SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/$basename_file"
        echo "Linked $basename_file"
    fi
done

echo ""
echo "Quadlets installed to $TARGET_DIR"
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

echo ""
echo "Available services:"
ls -1 "$TARGET_DIR"/*.container "$TARGET_DIR"/*.pod 2>/dev/null | xargs -n1 basename | sort
