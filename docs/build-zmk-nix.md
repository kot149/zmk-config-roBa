# zmk-nixを使ったroBaビルド手順

[zmk-nix](https://github.com/lilyinstarlight/zmk-nix) を使ってroBaのファームウェアをビルドする手順です。

> [!note]
> **[urob氏のzmk-config](https://github.com/urob/zmk-config)のローカルビルド環境の方おすすめです。**

Nixは再現性の高いビルドを可能にするパッケージマネージャです。
GitHub ActionsやDockerを使用したビルドよりも高速なビルドが可能になります。
筆者環境では、GitHub Actionsを使うビルドが2分ほど、Dockerを使用したビルドが1分ほどかかるのに対して、zmk-nixを使うと20～30秒ほどでした。

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
   parts = [ "R" "L" ]; # ZMK Studioを使用する場合、Centralである"R"を先に書く

   # ZMK Studioを有効にする場合
   enableZmkStudio = true;
   ```
   - ビルドに失敗する場合、以下も追記してみる
     ```nix
     extraCmakeFlags = [
       "-DCONFIG_CBPRINTF_LIBC_SUBSTS=y"
       "-DCONFIG_NEWLIB_LIBC=y"
     ];
     centralPart = "R";
     ```
1. ビルドする。resultフォルダにビルド結果が保存される
   ```sh
   nix build .#firmware
   ```
   - 以下のようにハッシュが違うというエラーが出る場合、`flake.nix`の`zephyrDepsHash`の値を、`got:`の方のハッシュに書き換える
     ```sh
     error: hash mismatch in fixed-output derivation:
           specified: sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
              got:    sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ```

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
