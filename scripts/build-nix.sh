#!/bin/bash
set -o pipefail

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

info_msg "Starting firmware builds with Nix..."

# 並行ビルド用の一時ファイルを準備
tmp_R=$(mktemp)
tmp_L=$(mktemp)

echo -e "\n${KEYBOARD} Building firmware.R..."
( nix build .#firmware.R --no-link --print-out-paths 2>&1 | tee "$tmp_R" ) & pid_R=$!
echo -e "${KEYBOARD} Building firmware.L..."
( nix build .#firmware.L --no-link --print-out-paths 2>&1 | tee "$tmp_L" ) & pid_L=$!

# ビルド完了待機と終了ステータス取得
wait $pid_R; r_status=$?
[ $r_status -eq 0 ] && success_msg "firmware.R build succeeded" || error_msg "firmware.R build failed"
wait $pid_L; l_status=$?
[ $l_status -eq 0 ] && success_msg "firmware.L build succeeded" || error_msg "firmware.L build failed"

echo -e "\n${BOLD}Build Results:${NC}"
if [ $r_status -eq 0 ] && [ $l_status -eq 0 ]; then
    success_msg "All builds completed successfully!\n"
    info_msg "Copying firmware files to build/nix ..."

    mkdir -p build/nix
    out_R=$(tail -n1 "$tmp_R")
    out_L=$(tail -n1 "$tmp_L")
    cp "$out_R"/zmk.uf2 build/nix/zmk_R.uf2
    cp "$out_L"/zmk.uf2 build/nix/zmk_L.uf2

    success_msg "Firmware files have been copied:"
    echo -e "${BLUE}  📁 Directory:${NC} build/nix/"
    echo -e "${BLUE}  └── Right:${NC} $(basename "$out_R")"
    echo -e "${BLUE}  └── Left:${NC} $(basename "$out_L")"
else
    error_msg "Some builds failed:"
    [ $r_status -ne 0 ] && error_msg "  firmware.R build failed"
    [ $l_status -ne 0 ] && error_msg "  firmware.L build failed"
    rm "$tmp_R" "$tmp_L"
    exit 1
fi

# クリーンアップ
rm "$tmp_R" "$tmp_L"

info_msg "Done."
