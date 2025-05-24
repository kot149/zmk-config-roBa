#!/bin/bash
set -o pipefail

# 引数処理
SIDE="${1:-R}"
if [ "$SIDE" != "R" ] && [ "$SIDE" != "L" ]; then
    echo "Usage: $0 [R|L]"
    echo "  R: Build right side firmware (default)"
    echo "  L: Build left side firmware"
    exit 1
fi

# Nix環境を読み込み、nixコマンドの存在を確認
if [ -e "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
elif [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

command -v nix >/dev/null 2>&1 || {
    echo "nix コマンドが見つかりません。Nixをインストールしてください: https://nixos.org/download.html"
    exit 1
}

# 表示用の色とアイコン定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

CHECK_MARK="✔"
CROSS_MARK="✗"
GEAR="⚙"
KEYBOARD="⌨"

success_msg() {
    echo -e "${GREEN}${CHECK_MARK} ${1}${NC}"
}
error_msg() {
    echo -e "${RED}${CROSS_MARK} ${1}${NC}"
}
info_msg() {
    echo -e "${BLUE}${GEAR} ${1}${NC}"
}

info_msg "Starting firmware build for side $SIDE with Nix..."

# ビルド処理
if [ "$SIDE" = "R" ]; then
    echo -e "\n${KEYBOARD} Building firmware.R..."
    if output=$(nix build .#firmware.R --no-link --print-out-paths 2>&1); then
        success_msg "firmware.R build succeeded"
        build_status=0
    else
        error_msg "firmware.R build failed"
        echo "$output"
        build_status=1
    fi
else
    echo -e "\n${KEYBOARD} Building firmware.L..."
    if output=$(nix build .#firmware.L --no-link --print-out-paths 2>&1); then
        success_msg "firmware.L build succeeded"
        build_status=0
    else
        error_msg "firmware.L build failed"
        echo "$output"
        build_status=1
    fi
fi

echo -e "\n${BOLD}Build Results:${NC}"
if [ $build_status -eq 0 ]; then
    success_msg "Build completed successfully!\n"
    info_msg "Copying firmware file to build/nix ..."

    mkdir -p build/nix
    out_path=$(echo "$output" | tail -n1)
    cp "$out_path"/zmk.uf2 "build/nix/zmk_${SIDE}.uf2"

    success_msg "Firmware file has been copied:"
    echo -e "${BLUE}  📁 Directory:${NC} build/nix/"
    echo -e "${BLUE}  └── ${SIDE} side:${NC} zmk_${SIDE}.uf2"
else
    error_msg "Build failed for firmware.${SIDE}"
    exit 1
fi

info_msg "Done."
