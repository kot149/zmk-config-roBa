# Dockerを使用したroBaローカルビルド手順
Dockerを使用して、roBaのファームウェアをGitHub Actionsを使わずローカルPCでビルドするための手順です。

> [!note]
> **[zmk-nixを使う方法](./build-zmk-nix.md) の方が高速なのでおすすめです。**

手順は基本的には公式ドキュメントに説明されている通りですが、具体的にroBaの場合はどういうコマンドを打てばいいのかを記載します。
なお、公式ドキュメントにはDocker(VSCode/Dev Conteiner CLI/Podman)/ネイティブ環境と複数パターン書かれていますが、ここではDocker+VSCodeでの方法だけ記載します。

コンテナや一部の中間ファイルを使いまわすことが可能になり、GitHub Actionsを使うよりビルド時間が短縮されます。
具体的にには、筆者の環境では、GitHub Actionsを使うとビルドに2分以上かかるのに対し、ローカルビルドでは40秒～1分程度で済むようになりました。

また、ビルド結果のダウンロード・解凍の手間も省けます。

目次
- [Dockerを使用したroBaローカルビルド手順](#dockerを使用したrobaローカルビルド手順)
	- [公式ドキュメント](#公式ドキュメント)
	- [環境構築](#環境構築)
		- [リポジトリのクローン](#リポジトリのクローン)
		- [ツールのインストール](#ツールのインストール)
		- [Dockerボリュームとコンテナの用意](#dockerボリュームとコンテナの用意)
			- [zmk-configのvolume作成](#zmk-configのvolume作成)
			- [zmk-modulesのvolume作成](#zmk-modulesのvolume作成)
			- [ZMKのコンテナ作成](#zmkのコンテナ作成)
		- [Westの初期化](#westの初期化)
	- [ビルド](#ビルド)
		- [初回ビルド](#初回ビルド)
		- [2回目以降のビルド](#2回目以降のビルド)
		- [ビルドスクリプト](#ビルドスクリプト)

## 公式ドキュメント
- [環境構築/コンテナ](https://zmk.dev/docs/development/local-toolchain/setup/container)
- [環境構築/ネイティブ](https://zmk.dev/docs/development/local-toolchain/setup/native)
- [ビルド](https://zmk.dev/docs/development/local-toolchain/build-flash)

## 環境構築

### リポジトリのクローン
zmk-config-roBaをクローンする。
フォークしたリポジトリを使う場合は`kumamuk-git`の部分を書き換えること。
```sh
git clone https://github.com/kumamuk-git/zmk-config-roBa.git
```

zmk-pmw3610-driverをzmk-modulesディレクトリにクローンする。
```sh
git clone https://github.com/kumamuk-git/zmk-pmw3610-driver.git zmk-modules/zmk-pmw3610-driver
```

zmkをクローンする。
```sh
git clone https://github.com/zmkfirmware/zmk.git
```

### ツールのインストール
- Docker Desktopをインストールする
- VSCodeをインストールする
- VSCodeのRemote Containers拡張機能をインストールする

### Dockerボリュームとコンテナの用意
zmk-configとzmk-modulesのボリュームと、ZMKのコンテナを作成する。

#### zmk-configのvolume作成
以下のコマンドを実行する。`/absolute/path/to/zmk-config/`は各自のクローンしたzmk-config-roBaへの絶対パスに置き換えること。
```sh
docker volume create --driver local -o o=bind -o type=none -o device="/absolute/path/to/zmk-config/" zmk-config
```
#### zmk-modulesのvolume作成
以下のコマンドを実行する。`/absolute/path/to/zmk-modules/`は各自のクローンしたzmk-modules(zmk-config-roBaの親ディレクトリ)への絶対パスに置き換えること。
```sh
docker volume create --driver local -o o=bind -o type=none -o device="/absolute/path/to/zmk-modules/" zmk-modules
```

#### ZMKのコンテナ作成
クローンしたzmkディレクトリをVSCodeで開く。

Command Paletteから`Remote: Show Remote Menu`を実行し、`Reopen in Container`を選択する。

コンテナが作成され、コンテナ内の`/workspaces/zmk/`ディレクトリでVSCodeが開かれる。

### Westの初期化

> [!important]
> 以降の操作は全てコンテナ内の`/workspaces/zmk`ディレクトリで行うこと。

以下のコマンドを順に実行する。
```sh
west init -l app
```
```sh
west update
```

## ビルド
### 初回ビルド
以下のコマンドを実行

- 右手用
	```sh
	west build -s app -d build/right -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_R -DZMK_EXTRA_MODULES=/workspaces/zmk-modules/zmk-pmw3610-driver
	```

- 左手用
	```sh
	west build -s app -d build/left  -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=roBa_L
	```

- リセット用
	```sh
	west build -s app -d build/reset -b seeeduino_xiao_ble -- -DZMK_CONFIG=/workspaces/zmk-config/config -DSHIELD=settings_reset
	```

### 2回目以降のビルド
2回目以降のビルドでは、`-b`以降のオプションを省略してビルドを高速化できる。
- 右手用
	```sh
	west build -s app -d build/right
	```
- 左手用
	```sh
	west build -s app -d build/left
	```
- リセット用
	```sh
	west build -s app -d build/reset
	```
 
