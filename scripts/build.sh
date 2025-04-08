#!/bin/bash

# カラーコード定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# アイコン定義
CHECK_MARK="✔"
CROSS_MARK="✗"
GEAR="⚙"
KEYBOARD="⌨"

# ステータスメッセージ関数
success_msg() {
    echo -e "${GREEN}${CHECK_MARK} ${1}${NC}"
}

error_msg() {
    echo -e "${RED}${CROSS_MARK} ${1}${NC}"
}

info_msg() {
    echo -e "${BLUE}${GEAR} ${1}${NC}"
}

# コマンドライン引数の解析
FULL_BUILD=false
while getopts "f" opt; do
    case $opt in
        f)
            FULL_BUILD=true
            ;;
        \?)
            echo "使用法: $0 [-f]"
            echo "  -f: フルビルドを実行 (オプションなしの場合は高速ビルド)"
            exit 1
            ;;
    esac
done

cd /workspaces/zmk

# 出力ディレクトリの作成
OUTPUT_DIR="/workspaces/zmk-config/build"
mkdir -p "$OUTPUT_DIR"

info_msg "Starting firmware builds..."

# モジュールの設定
EXTRA_MODULES_LEFT=(
    "/workspaces/zmk-modules/zmk-listeners"
    "/workspaces/zmk-modules/zmk-rgbled-widget"
)
EXTRA_MODULES_RIGHT=(
    "/workspaces/zmk-modules/zmk-pmw3610-driver"
)
EXTRA_MODULES_RIGHT+=(${EXTRA_MODULES_LEFT[@]})

# ;で区切って結合し、""で囲う
EXTRA_MODULES_STR_LEFT=$(IFS=';'; echo "\"${EXTRA_MODULES_LEFT[*]}\"")
EXTRA_MODULES_STR_RIGHT=$(IFS=';'; echo "\"${EXTRA_MODULES_RIGHT[*]}\"")

# ビルドコマンドの設定
if [ "$FULL_BUILD" = true ]; then
    # フルビルド用のコマンド
    RIGHT_BUILD_CMD="west build -p -s app -d build/right -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_R -DZMK_EXTRA_MODULES=$EXTRA_MODULES_STR_RIGHT"
    LEFT_BUILD_CMD="west build -p -s app -d build/left  -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_L -DZMK_EXTRA_MODULES=$EXTRA_MODULES_STR_LEFT"
    RESET_BUILD_CMD="west build -p -s app -d build/reset -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=settings_reset"
    info_msg "Performing full build..."
else
    # 高速ビルド用のコマンド
    RIGHT_BUILD_CMD="west build -s app -d build/right"
    LEFT_BUILD_CMD="west build -s app -d build/left"
    RESET_BUILD_CMD="west build -s app -d build/reset"
    info_msg "Performing quick build..."
fi

# echo $RIGHT_BUILD_CMD
# exit

# 並行してビルドを実行
echo -e "\n${KEYBOARD} Building right-hand firmware..."
(eval "$RIGHT_BUILD_CMD" && success_msg "Right build completed") &
right_pid=$!

echo -e "${KEYBOARD} Building left-hand firmware..."
(eval "$LEFT_BUILD_CMD" && success_msg "Left build completed") &
left_pid=$!

echo -e "${KEYBOARD} Building reset firmware..."
(eval "$RESET_BUILD_CMD" && success_msg "Reset build completed") &
reset_pid=$!

# 全てのビルドプロセスが完了するのを待機
wait $right_pid
right_status=$?
wait $left_pid
left_status=$?
wait $reset_pid
reset_status=$?

echo -e "\n${BOLD}Build Results:${NC}"

# ビルド結果の確認とファイルのコピー
if [ $right_status -eq 0 ] && [ $left_status -eq 0 ] && [ $reset_status -eq 0 ]; then
    success_msg "All builds completed successfully!\n"

    # ビルドファイルのコピー
    info_msg "Copying firmware files to $OUTPUT_DIR ..."
    cp build/right/zephyr/zmk.uf2 "$OUTPUT_DIR/roBa_R-seeeduino_xiao_ble-zmk.uf2"
    cp build/left/zephyr/zmk.uf2 "$OUTPUT_DIR/roBa_L-seeeduino_xiao_ble-zmk.uf2"
    cp build/reset/zephyr/zmk.uf2 "$OUTPUT_DIR/settings_reset-seeeduino_xiao_ble-zmk.uf2"

    success_msg "Firmware files have been copied to host OS at:"
    echo -e "${BLUE}  📁 Directory:${NC} zmk-config/build/"
    echo -e "${BLUE}  └── Right:${NC} roBa_R-seeeduino_xiao_ble-zmk.uf2"
    echo -e "${BLUE}  └── Left:${NC}  roBa_L-seeeduino_xiao_ble-zmk.uf2"
    echo -e "${BLUE}  └── Reset:${NC} settings_reset-seeeduino_xiao_ble-zmk.uf2"
else
    error_msg "Some builds failed:"
    [ $right_status -ne 0 ] && error_msg "  Right build failed"
    [ $left_status -ne 0 ] && error_msg "  Left build failed"
    [ $reset_status -ne 0 ] && error_msg "  Reset build failed"
    exit 1
fi
