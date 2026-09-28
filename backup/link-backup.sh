#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

mkdir -p "$SYSTEMD_USER_DIR"
ln -sfn "$SCRIPT_DIR/backup.service" "$SYSTEMD_USER_DIR/backup.service"
ln -sfn "$SCRIPT_DIR/backup.timer" "$SYSTEMD_USER_DIR/backup.timer"

systemctl --user daemon-reload
systemctl --user enable --now backup.timer
