#!/bin/bash

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

out_dir=$(nix build --no-link --print-out-paths)

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

cp $out_dir/* build/nix/

echo "Build complete"
