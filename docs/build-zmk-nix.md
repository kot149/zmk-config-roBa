# zmk-nixを使ったroBaビルド手順

[zmk-nix](https://github.com/lilyinstarlight/zmk-nix) を使ってroBaのファームウェアをビルドする手順です。

Nixは再現性の高いビルドを可能にするパッケージマネージャです。
厳密なビルドキャッシュの管理により、高速なビルドが可能になります。
GitHub Actionsを使うビルドが2分10秒ほど、Dockerを使用したビルドが1分10秒ほどかかるのに大して、zmk-nixを使うと30秒ほどで済みます。

## 手順
1. Windowsの場合、[公式ドキュメント](https://learn.microsoft.com/ja-jp/windows/wsl/install) に従い、WSLを導入する。以下WSL内で作業する
1. [公式ドキュメント](https://nixos.org/download/) に従い、Nixをインストールする
1. Nix-commandを有効化する
   ```sh
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```
1. roBaのリポジトリをクローンする。
  フォークしたリポジトリを使う場合は`kumamuk-git`の部分を書き換えること。
   ```sh
   git clone https://github.com/kumamuk-git/zmk-config-roBa.git
   cd zmk-config-roBa
   ```
1. Nix flakeを初期化する
   ```sh
   nix flake init --template github:lilyinstarlight/zmk-nix
   ```
2. `flake.nix`を編集する
   ```nix
   board = "seeeduino_xiao_ble";
   shield = "roBa_%PART%";
   parts = [ "R" "L" ];
   ```
1. ビルドする
   ```sh
   nix build .#firmware
   ```
   resultフォルダにビルド結果が保存される。
1. 以下のようにハッシュが違うというエラーが出る場合
   ```sh
   error: hash mismatch in fixed-output derivation:
         specified: sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            got:    sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   `flake.nix`の`zephyrDepsHash`の値を、`got:`の方のハッシュに書き換える

## ビルドオプション
### 片側だけビルドする
以下のコマンドで片側だけビルドできる。
```sh
nix build .#firmware.R
nix build .#firmware.L
```

### resultフォルダ以外に保存する
実はresultフォルダはシンボリックリンクで、`/nix/store/`にあるフォルダを指している。
`--print-out-paths`オプションをつけると、シンボリックリンクの元のビルド結果のパスが表示される。
```sh
nix build .#firmware --print-out-paths
```

手動でそこからコピーすればOK。
```sh
cp /nix/store/.../zmk.uf2 build/
```

シンボリックリンクを作成しないようにするには`--no-link`オプションをつける。
```sh
nix build .#firmware --no-link
```
