# roBa ローカルビルド手順
roBaのファームウェアをGitHub Actionsを使わずローカルPCでビルドするための手順です。

コンテナや一部の中間ファイルを使いまわすことが可能になりビルド時間が短縮されることに加え、ビルド結果のダウンロード・解凍の手間を省くことができます。

> [!Warning]
> 同じ手順で環境構築してもビルドできなかった経験があるので、もしかしたら不備があるかもしれません。<br>
> また、途中でZMKのCMakeList.txtを書き換えますが、本来いじらなくてもできるはずで、おそらく正しいやり方ではないです。

目次
- [roBa ローカルビルド手順](#roba-ローカルビルド手順)
	- [環境構築](#環境構築)
		- [zmk-config-roBaの準備](#zmk-config-robaの準備)
		- [VSCodeとDockerのインストールする](#vscodeとdockerのインストールする)
		- [Dockerコンテナの用意](#dockerコンテナの用意)
			- [zmk-configのvolume作成](#zmk-configのvolume作成)
			- [ZMKのコンテナ作成](#zmkのコンテナ作成)
		- [Westの初期化](#westの初期化)
	- [ビルド](#ビルド)
		- [ビルドスクリプト](#ビルドスクリプト)


## 環境構築

### zmk-config-roBaの準備
zmk-config-roBaをクローンする。
フォークしたリポジトリを使う場合は`kumamuk-git`の部分を書き換えること。
```sh
git clone https://github.com/kumamuk-git/zmk-config-roBa.git
```

`zmk-config-roBa`内で、zmk-pmw3610-driverをクローンする。
```sh
cd zmk-config-roBa
git clone https://github.com/kumamuk-git/zmk-pmw3610-driver.git
```

### VSCodeとDockerのインストールする
- Docker Desktopをインストールする
- VSCodeをインストールする
- VSCodeのRemote Containersエクステンションをインストールする

### Dockerコンテナの用意
zmk-configのvolumeとZMKのコンテナを作成する。

#### zmk-configのvolume作成
以下のコマンドを実行する。`/absolute/path/to/zmk-config/`は各自のクローンしたzmk-config-roBaへのパスに置き換えること。
```sh
docker volume create --driver local -o o=bind -o type=none -o device="/absolute/path/to/zmk-config/" zmk-config
```

#### ZMKのコンテナ作成
ZMKのリポジトリをクローンし、VSCodeで開く。以下のコマンドを実行する。
```sh
git clone https://github.com/zmkfirmware/zmk.git
code zmk
```

ZMKリポジトリ内にコンテナの設定が書かれているので、そのコンテナをVSCodeで開く。

### Westの初期化
※以降の操作は全てコンテナ内で行うこと。※

`/workspaces/zmk/app/CMakeList.txt`の6行目の外部モジュールに`zmk-pmw3610-driver`を加える
```cmake
set(ZEPHYR_EXTRA_MODULES "${ZMK_EXTRA_MODULES};${CMAKE_CURRENT_SOURCE_DIR}/module;${CMAKE_CURRENT_SOURCE_DIR}/keymap-module;/workspaces/zmk-config/zmk-pmw3610-driver")
```

以下のコマンドを順に実行する。
```sh
west init -l app
west update
```

## ビルド
以下のコマンドを実行
```sh
# 右手用
west build -s /workspaces/zmk/app -d build/right -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_R -DZMK_EXTRA_MODULES=/workspaces/zmk-config
# 左手用
west build -s /workspaces/zmk/app -d build/left -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_L -DZMK_EXTRA_MODULES=/workspaces/zmk-config
# リセット用
west build -s /workspaces/zmk/app -d build/reset -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=settings_reset -DZMK_EXTRA_MODULES=/workspaces/zmk-config
```

2回目以降のビルドでは、`-b`以降のオプションを省略してビルドを高速化できる。
```sh
# 右手用
west build -s /workspaces/zmk/app -d build/right
# 左手用
west build -s /workspaces/zmk/app -d build/left
# リセット用
west build -s /workspaces/zmk/app -d build/reset
```

### ビルドスクリプト
このリポジトリの`build.sh`は上記3つのビルドを同時並行で行い、結果を`zmk-config-roBa/build`に保存するスクリプトである。
以下のコマンドで実行できる。
```sh
# 初回ビルド
./build.sh -f

# 2回目以降の省略ビルド
./build.sh
```
