#!/usr/bin/env bash
# Install Godot 4.7.2 (Linux x86_64) to /usr/local/bin/godot4 for agents/CI.
set -euo pipefail
GODOT_VER="${GODOT_VER:-4.7.2}"
TMP="${TMPDIR:-/tmp}/godot-install-$$"
mkdir -p "$TMP"
cd "$TMP"
URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VER}-stable/Godot_v${GODOT_VER}-stable_linux.x86_64.zip"
echo "Downloading $URL"
curl -fsSL -o godot.zip "$URL"
unzip -o godot.zip
sudo mv "Godot_v${GODOT_VER}-stable_linux.x86_64" /usr/local/bin/godot4
sudo chmod +x /usr/local/bin/godot4
godot4 --version
echo "Installed godot4 → $(command -v godot4)"
rm -rf "$TMP"
