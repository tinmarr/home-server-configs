#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/containers/systemd"
REPO_DIR="${HOME}/home-server-configs"

echo "Setting up Podman quadlets..."

mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/config"

for file in "$SCRIPT_DIR"/*.container "$SCRIPT_DIR"/*.pod; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/$basename_file"
        echo "Linked $basename_file"
    fi
done

ln -sf "$SCRIPT_DIR/.env" "$TARGET_DIR/config/.env"
echo "Linked config/.env"

ln -sf "$SCRIPT_DIR/immich.env" "$TARGET_DIR/config/immich.env"
echo "Linked config/immich.env"

echo ""
echo "Quadlets installed to $TARGET_DIR"
echo ".env linked to $TARGET_DIR/config/.env"
echo ""
echo "Config directories (must exist):"
echo "  $REPO_DIR/docker/management/homepage-config"
echo "  $REPO_DIR/docker/management/kuma-data"
echo "  $REPO_DIR/docker/misc/jellyfin-config"
echo "  $REPO_DIR/docker/misc/jellyseerr-config"
echo "  $REPO_DIR/docker/misc/st-data"
echo "  $REPO_DIR/docker/tinflix/wg-config"
echo "  $REPO_DIR/docker/tinflix/qbit-config"
echo "  $REPO_DIR/docker/tinflix/prowlarr-config"
echo "  $REPO_DIR/docker/tinflix/radarr-config"
echo "  $REPO_DIR/docker/tinflix/sonarr-config"
echo "  $REPO_DIR/docker/pihole/etc-pihole"
echo "  $REPO_DIR/docker/immich/pgdata"
echo ""

echo "Reloading systemd daemon..."
systemctl --user daemon-reload

echo ""
echo "Available services:"
ls -1 "$TARGET_DIR"/*.container "$TARGET_DIR"/*.pod 2>/dev/null | xargs -n1 basename | sort
