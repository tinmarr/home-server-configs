#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_DIR="$HOME/.config/containers/systemd"
SERVICE_DIR="$HOME/.config/systemd/user"
REPO_DIR="${HOME}/home-server-configs"

echo "Setting up rootless Podman quadlets..."

mkdir -p "$CONTAINER_DIR"
mkdir -p "$SERVICE_DIR"

for file in "$SCRIPT_DIR"/*.container "$SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        ln -sf "$file" "$CONTAINER_DIR/$basename_file"
        echo "Linked $basename_file"
    fi
done

for file in "$SCRIPT_DIR"/*.service; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        ln -sf "$file" "$SERVICE_DIR/$basename_file"
        echo "Linked $basename_file"
    fi
done

echo ""
echo "Quadlets installed to $CONTAINER_DIR"
echo ""
echo "Config directories (must exist):"
echo "  $HOME/service-data/etc-pihole"
echo "  $HOME/service-data/ha-config"
echo "  $HOME/service-data/matter-server"
echo "  $HOME/service-data/otbr"
echo ""

echo "Reloading systemd daemon..."
systemctl --user daemon-reload

echo ""
echo "Available containers:"
ls -1 "$CONTAINER_DIR"/*.container "$CONTAINER_DIR"/*.pod 2>/dev/null | xargs -n1 basename | sort
echo ""
echo "Available services:"
ls -1 "$SERVICE_DIR"/*.service 2>/dev/null | xargs -n1 basename | sort
