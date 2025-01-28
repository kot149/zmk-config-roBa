# キーマップ
自分の考えるキーマップについて語り、その実装方法を紹介する。

目次
- [キーマップ](#キーマップ)
	- [全角半角](#全角半角)
	- [Alt-Tab, Cmd-Tab, Ctrl-Tab](#alt-tab-cmd-tab-ctrl-tab)
		- [1. タイムアウトでAltを離す](#1-タイムアウトでaltを離す)
			- [作り方](#作り方)
		- [2. 確定は別キーにする](#2-確定は別キーにする)
		- [3. Layer-TapでAltを代用](#3-layer-tapでaltを代用)
			- [作り方](#作り方-1)
		- [4. トラボでTabを代用](#4-トラボでtabを代用)
			- [作り方](#作り方-2)
	- [Auto Mouse関連](#auto-mouse関連)

## 全角半角
全角半角を1キーだけでのトグル式にするのではなく、変換・無変換に分ける方がストレスが減るというのは有名な話。

これの本質は、同じ動作で異なる効果を出すのをやめて、異なる効果には異なる動作をさせることだ。
変換無変換は異なる2キーに分けることで解決したわけだが、自分は**シングルタップとダブルタップで分ける方法**を推したい。

これを作るにはTap DanceでInternational 2とInternational 1を割り当てればいいが、それだけでは微妙に使いにくい。というのも、
- 2回目のタップがないことが確定するまで、シングルタップを発行してくれない
- 3回連続でタップするとシングルタップと判定されてしまう

からだ。
前者はスマホのタップとかでも発生する一般的な問題で、Tap Danceとしては正しい挙動だが、全角半角の場合、それを無視して高速化が見込める。ダブルタップの確定を待たずにシングルタップの効果を発行しても(ダブルタップすると、同時にシングルタップの効果も発行されていても)問題にならないからだ。

このようなeagerなTap Danceは[ZMKのissueに要望が上がっており](https://github.com/zmkfirmware/zmk/issues/2528) フラグとして実装することが検討されているが、まだ実装されていない。が、issueにも書かれている通り、Sticky Layerで作ることができる。

ちなみに、AutoHotKeyやKarabiner Elementsでもこの機能は実現できる。

## Alt-Tab, Cmd-Tab, Ctrl-Tab
アプリやタブを切り替えるショートカット。
Altの場合で書くと、`[Alt↓]`, `[Tab↓↑]`×N回, `[Alt↑]`のような動作が求められるが、これ1つのためにレイヤー0のキーを2つ消費したくない。
機能を損なわずに、少ないキー数を実現するには、以下の4つの方法が考えられる。
1. タイムアウトでAltを離す
2. 確定は別キーにする
3. Layer-TapでAltを代用
4. トラボでTabを代用

### 1. タイムアウトでAltを離す
完全に1キーでやるならこれしかない。
個人的には体感動作が遅くなるので微妙。

#### 作り方
以下のマクロで作れる。
```dts
/{
	behaviors {
		alt_tab: alt_tab {
			compatible = "zmk,behavior-macro-two-param";
			#binding-cells = <2>;
			bindings = <&macro_param_1to1 &kt_on MACRO_PLACEHOLDER &macro_param_2to1 &kp MACRO_PLACEHOLDER &macro_param_1to1 &sk MACRO_PLACEHOLDER &macro_param_1to1 &kt_off MACRO_PLACEHOLDER>;
			label = "ALT_TAB";
		};
	}

	keymap {
		Default {
			bindings = <
				&alt_tab LEFT_ALT TAB
			>;
		}
	}
}
```

### 2. 確定は別キーにする
- Windowsの場合
  Ctrlを押しながらAlt+Tabを押すと最後の`[Alt↑]`をスキップしたような動作をしてくれて、Enterで確定できる。
- Macの場合
  サードパーティアプリのAltTabの場合、Altを離しても確定しない・Enterで確定するように設定で変えられる。
  Mac標準のCmd+Tabだと多分無理。
- iPadの場合
  多分無理。

Enterはどこかに割り当ててるだろうから実質1キー消費で済む。

作り方は簡単なので省略。

### 3. Layer-TapでAltを代用
- Layer-Tapの移動先レイヤでマクロを押すと`[Alt↓]` `[Tab↓↑]`
- 続けて押すと`[Tab↓↑]`
- Layer-Tapを離すと`[Alt↑]`

みたいなのをマクロとレイヤー移動の組み合わせで作れる。
Layer-Tapはどこかにあるだろうから実質1キー消費。レイヤー0のキー数消費に関しては実質0と言ってもいい。

自分はさらに、TabとShift+Tabを並べ、Alt+TabとAlt+Shift+Tabができるようにした上で逆から押し始めたらCtrl+Tab, Ctrl+Shift+Tabとして動作するようにしている。

作り方はかなり煩雑。

#### 作り方
- lt(Layer-Tap)のreleaseに`[Alt↑]`を仕込んだマクロを作る
  - mo(Momentary Layer)のreleaseに`[Alt↑]`を仕込んだマクロを作る
  - 新規Hold-Tap compatibleのbehaviorを作成し、上記moとkpをbindする
- TabとShift+Tabを並べたレイヤーxと、逆にShift+TabとTabを並べたレイヤーyを作る
- タップするとAlt pressとTab tapを発行し、レイヤーxへtoするマクロを作成し、lt先レイヤーに配置する
- タップするとCtrl pressとTab tapを発行し、レイヤーyへtoするマクロを作成し、lt先レイヤーに配置する
なお、`[Alt↑]`や`[Ctrl↑]`は10回ぐらいやらないと動作してくれないときがある。

### 4. トラボでTabを代用
トラボの上下左右にキーを割り当てる機能を使う。

#### 作り方
方法3のマクロを流用するか、専用のレイヤーを作成し、単独の修飾キーにレイヤー移動をセットしておく。

## Auto Mouse関連
wip