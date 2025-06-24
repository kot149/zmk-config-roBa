#!/bin/bash

# スクリプトの場所を基準にしたデフォルト値
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"  # scripts の親ディレクトリ（zmk-config-roBa）
TARGET_DIR="$(dirname "$SOURCE_DIR")/zmk-config-moNa2"  # zmk-config-roBa の親の zmk-config-moNa2
SOURCE_PATTERN="roBa"
TARGET_PATTERN="moNa2"
DRY_RUN=false
EXCLUDE_DIRS=(".git" ".vscode" "build" "docs")
EXCLUDE_FILES=("convert-to-moNa2.ps1" "convert-to-moNa2.sh" "README.md")

# ヘルプ表示関数
show_help() {
    echo "使用方法: $0 [オプション]"
    echo "オプション:"
    echo "  -s, --source-dir DIR     ソースディレクトリ (デフォルト: スクリプト場所の親ディレクトリ)"
    echo "  -t, --target-dir DIR     ターゲットディレクトリ (デフォルト: ソースディレクトリの隣のzmk-config-moNa2)"
    echo "  -p, --source-pattern STR 置換元パターン (デフォルト: roBa)"
    echo "  -r, --target-pattern STR 置換先パターン (デフォルト: moNa2)"
    echo "  -n, --dry-run           実際にファイルをコピーせずに動作を確認"
    echo "  -h, --help              このヘルプを表示"
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source-dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -t|--target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -p|--source-pattern)
            SOURCE_PATTERN="$2"
            shift 2
            ;;
        -r|--target-pattern)
            TARGET_PATTERN="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# バナーを表示
echo -e "\033[36mZMK設定ファイルコピースクリプト\033[0m"
if [ "$DRY_RUN" = true ]; then
    echo -e "\033[33m[DRY RUN MODE] 実際のファイル操作は行いません\033[0m"
fi
echo -e "\033[33mソース: $SOURCE_DIR\033[0m"
echo -e "\033[33mターゲット: $TARGET_DIR\033[0m"
echo -e "\033[33m置換: '$SOURCE_PATTERN' → '$TARGET_PATTERN'\033[0m"
echo -e "\033[33m除外ディレクトリ: ${EXCLUDE_DIRS[*]}\033[0m"
echo -e "\033[33m除外ファイル: ${EXCLUDE_FILES[*]}\033[0m"
echo ""

# 絶対パスに変換
SOURCE_DIR=$(realpath "$SOURCE_DIR")
TARGET_DIR=$(realpath "$TARGET_DIR")

# ターゲットディレクトリが存在するか確認
if [[ -d "$TARGET_DIR" ]]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[33m[DRY RUN] ターゲットディレクトリが既に存在します: $TARGET_DIR\033[0m"
        echo -e "\033[33m[DRY RUN] .gitディレクトリとREADME.mdを除いて既存の内容をクリアします\033[0m"
    else
        echo -n "ターゲットディレクトリが既に存在します。上書きしますか？ (Y/N): "
        read -r confirmation
        if [[ "$confirmation" != "Y" && "$confirmation" != "y" ]]; then
            echo -e "\033[31m処理を中止しました。\033[0m"
            exit 0
        fi

        # .gitディレクトリとREADME.mdを除いて既存の内容をクリア
        echo -e "\033[33mターゲットディレクトリの内容をクリアしています...\033[0m"
        find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name ".git" ! -name "README.md" -exec rm -rf {} + 2>/dev/null
        echo -e "\033[32mターゲットディレクトリをクリアしました。\033[0m"
    fi
else
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[33m[DRY RUN] ターゲットディレクトリを作成します: $TARGET_DIR\033[0m"
    else
        # ターゲットディレクトリを作成
        mkdir -p "$TARGET_DIR"
        echo -e "\033[32mターゲットディレクトリを作成しました: $TARGET_DIR\033[0m"
    fi
fi

# バイナリファイルかどうかをチェックする関数
is_binary_file() {
    local file="$1"
    local text_extensions=("yml" "yaml" "defconfig" "shield" "conf" "overlay" "dtsi" "json" "keymap" "md" "ps1" "sh" "gitignore")

    # 拡張子チェック
    local extension="${file##*.}"
    for ext in "${text_extensions[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 1  # テキストファイル
        fi
    done

    # ファイル名が .gitignore の場合
    if [[ "$(basename "$file")" == ".gitignore" ]]; then
        return 1  # テキストファイル
    fi

    # file コマンドでチェック
    if command -v file >/dev/null 2>&1; then
        if file "$file" | grep -q "text"; then
            return 1  # テキストファイル
        fi
    fi

    return 0  # バイナリファイル
}

# ディレクトリが除外対象かチェックする関数
is_excluded_dir() {
    local dir_path="$1"

    # パスに除外ディレクトリが含まれているかチェック（完全一致）
    for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
        # パスが除外ディレクトリで始まるか、パス内に/除外ディレクトリ/が含まれるかをチェック
        if [[ "$dir_path" == "$exclude_dir" ]] || [[ "$dir_path" == "$exclude_dir"/* ]] || [[ "$dir_path" == *"/$exclude_dir" ]] || [[ "$dir_path" == *"/$exclude_dir/"* ]]; then
            return 0  # 除外対象
        fi
    done

    return 1  # 除外対象ではない
}

# ファイルが除外対象かチェックする関数
is_excluded_file() {
    local filename="$1"
    for exclude_file in "${EXCLUDE_FILES[@]}"; do
        if [[ "$filename" == "$exclude_file" ]]; then
            return 0  # 除外対象
        fi
    done
    return 1  # 除外対象ではない
}

# ファイルをコピーして内容を置換する関数
copy_and_replace_content() {
    local source_path="$1"
    local target_path="$2"

    if [ "$DRY_RUN" = true ]; then
        if is_binary_file "$source_path"; then
            echo -e "\033[37m[DRY RUN] コピー: $source_path -> $target_path\033[0m"
        else
            echo -e "\033[32m[DRY RUN] コピー+置換: $source_path -> $target_path\033[0m"
        fi
        return
    fi

    # ターゲットディレクトリを作成
    mkdir -p "$(dirname "$target_path")"

    if is_binary_file "$source_path"; then
        # バイナリファイルはそのままコピー
        cp "$source_path" "$target_path"
        echo -e "\033[37mコピー: $source_path -> $target_path\033[0m"
    else
        # テキストファイルは内容を置換してコピー（大文字小文字のパターンを考慮）
        sed -e "s|roBa|moNa2|g" -e "s|ROBA|MONA2|g" -e "s|roba|mona2|g" "$source_path" > "$target_path"
        echo -e "\033[32mコピー+置換: $source_path -> $target_path\033[0m"
    fi
}

# ファイル数をカウント
total_files=0
processed_files=0

echo "ファイル数をカウント中..."
while IFS= read -r -d '' file; do
    relative_path="${file#$SOURCE_DIR/}"
    dir_path=$(dirname "$relative_path")
    filename=$(basename "$file")

    # 除外チェック（相対パス全体とファイル名両方をチェック）
    if ! is_excluded_dir "$relative_path" && ! is_excluded_file "$filename"; then
        ((total_files++))
    fi
done < <(find "$SOURCE_DIR" -type f -print0)

echo "処理対象ファイル数: $total_files"
echo ""

# ファイルをコピーしながら内容とファイル名を置換
while IFS= read -r -d '' file; do
    relative_path="${file#$SOURCE_DIR/}"
    dir_path=$(dirname "$relative_path")
    filename=$(basename "$file")

    # 除外チェック（相対パス全体とファイル名両方をチェック）
    if ! is_excluded_dir "$relative_path" && ! is_excluded_file "$filename"; then
        # ファイル名とディレクトリパスの置換（大文字小文字のパターンを考慮）
        new_filename="$filename"
        new_filename="${new_filename//roBa/moNa2}"
        new_filename="${new_filename//ROBA/MONA2}"
        new_filename="${new_filename//roba/mona2}"
        
        new_dir_path="$dir_path"
        new_dir_path="${new_dir_path//roBa/moNa2}"
        new_dir_path="${new_dir_path//ROBA/MONA2}"
        new_dir_path="${new_dir_path//roba/mona2}"

        # ターゲットパスを作成
        if [[ "$new_dir_path" == "." ]]; then
            target_file_path="$TARGET_DIR/$new_filename"
        else
            target_file_path="$TARGET_DIR/$new_dir_path/$new_filename"
        fi

        # ファイルをコピーして内容を置換
        copy_and_replace_content "$file" "$target_file_path"

        ((processed_files++))
        echo "進捗: $processed_files / $total_files ファイル"
    fi
done < <(find "$SOURCE_DIR" -type f -print0)

echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "\033[32m[DRY RUN] 完了！\033[0m"
    echo -e "\033[32m[DRY RUN] $processed_files ファイルが処理対象です。\033[0m"
    echo -e "\033[32m[DRY RUN] ターゲットディレクトリ: $TARGET_DIR\033[0m"
else
    echo -e "\033[32mコピー完了！\033[0m"
    echo -e "\033[32m$processed_files ファイルを処理しました。\033[0m"
    echo -e "\033[32mターゲットディレクトリ: $TARGET_DIR\033[0m"
fi
