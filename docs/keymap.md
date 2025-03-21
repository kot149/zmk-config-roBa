# キーマップ
キーマップについて語り、その設定方法を紹介する。
なお、ZMK(roBa)を中心に書くが、一部QMK(Keyball)や、AutoHotKeyやKarabiner Elements(非カスタムキーボード向け)の話も書くかもしれない。

目次
- [キーマップ](#キーマップ)
  - [全角半角](#全角半角)
    - [作り方](#作り方)
  - [Alt-Tab, Cmd-Tab, Ctrl-Tab](#alt-tab-cmd-tab-ctrl-tab)
    - [1. タイムアウトでAltを離す](#1-タイムアウトでaltを離す)
      - [作り方](#作り方-1)
    - [2. 確定は別キーにする](#2-確定は別キーにする)
    - [3. Layer-TapでAltを代用](#3-layer-tapでaltを代用)
      - [作り方](#作り方-2)
    - [4. トラボでTabを代用](#4-トラボでtabを代用)
      - [作り方](#作り方-3)
  - [Auto Mouse Layer関連](#auto-mouse-layer関連)
    - [作り方](#作り方-4)
      - [マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける](#マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける)
      - [マウスキーを押したらタイムアウトを延長する・マウスキーを押したらマウスレイヤーを抜ける](#マウスキーを押したらタイムアウトを延長するマウスキーを押したらマウスレイヤーを抜ける)
  - [Input Processorあれこれ](#input-processorあれこれ)
    - [低CPI/高CPIモード](#低cpi高cpiモード)
    - [スクロールレイヤー](#スクロールレイヤー)
    - [オートマウスレイヤー](#オートマウスレイヤー)

## 全角半角
全角半角を1キーだけでのトグル式にするのではなく、変換・無変換に分ける方がストレスが減るというのは有名な話。

これの本質は、同じ動作で異なる効果を出すのをやめて、異なる効果には異なる動作をさせることだ。
変換無変換は異なる2キーに分けることで解決したわけだが、個人的には**シングルタップとダブルタップで分ける方法**を推したい。

シングルタップとダブルタップで異なる動作をするのは、マウスのダブルクリックで広く普及しているが、一般的なキーボードにはなぜか採用されていない。QMKやZMKでは、Tap DanceというN回タップにN個の異なる動作を割り当てる機能がある。

ではTap Danceを使ってInternational 2とInternational 1を割り当てようとなるが、それだけでは微妙に使いにくい。というのも、
- 2回目のタップがないことが確定するまで、シングルタップを発行してくれない(遅延が発生する)
- 3回連続でタップするとシングルタップと判定されてしまう

からだ。
前者はスマホのタップとかでも発生する一般的な問題で、Tap Danceとしては正しい挙動だが、全角半角の場合、それを無視して高速化が見込める。というのも、ダブルタップの確定を待たずにシングルタップの効果を発行しても(ダブルタップ時、同時にシングルタップの効果も発行されていても)問題にならないからだ。

このようなeagerなTap Danceは[ZMKのissueに要望が上がっており](https://github.com/zmkfirmware/zmk/issues/2528) 、フラグとして実装することが検討されているが、まだ実装されていない。が、issueにも書かれている通り、Sticky Layerで作ることができる。

ちなみに、AutoHotKeyやKarabiner Elementsでもこの機能は実現できる。

### 作り方
以下のようなSticky Layerを使ったマクロで作れる。
sl_250のrelease-after-msを変更すると、タイムアウト時間を変更できる。
```dts
/ {
    macros {
        eager_tap_dance: eager_tap_dance {
            compatible = "zmk,behavior-macro-two-param";
            #binding-cells = <2>;
            bindings =
                <&macro_press>,
                <&macro_param_1to1 &kp MACRO_PLACEHOLDER>,
                <&macro_pause_for_release>,
                <&macro_release>,
                <&macro_param_1to1 &kp MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&exit_AML &macro_param_2to1 &sl_250 MACRO_PLACEHOLDER>;

            label = "eager_tap_dance";
        };
    };

    behaviors {
        sl_250: sl_250 {
            compatible = "zmk,behavior-sticky-key";
            label = "SL_250";
            bindings = <&mo>;
            #binding-cells = <1>;
            release-after-ms = <250>;
        };
    };

    keymap {
        layer_0 {
            bindings = <
                &eager_tap_dance LANGUAGE_2 1
            >;
        };

        layer_1 {
            bindings = <
                &eager_tap_dance LANGUAGE_1 1
            >;
        };
    };
};
```

## Alt-Tab, Cmd-Tab, Ctrl-Tab
アプリやタブを切り替えるショートカット。以下、Altの場合で書く。

これらのショートカットは単純にAlt+Tabを押すだけでなく、`[Alt↓]`, `[Tab↓↑]`×N回, `[Alt↑]`のような動作が求められるので、少ないキー数で実現するには工夫が必要。

機能を損なうことなく少ないキー数で実現するには、以下の4つの方法が考えられる。
1. タイムアウトでAltを離す
2. 確定は別キーにする
3. Layer-TapでAltを代用
4. トラボでTabを代用

### 1. タイムアウトでAltを離す
完全に1キーでやるならこれしかない。
個人的には体感動作が遅くなる・迷ってる間にタイムアウトしてしまうと困るので微妙。

#### 作り方
以下のマクロで作れる。
```dts
&sk { release-after-ms = <700>; }; // タイムアウト時間を設定

/{
    behaviors {
        alt_tab: alt_tab {
            compatible = "zmk,behavior-macro-two-param";
            #binding-cells = <2>;
            bindings =
                <&macro_param_1to1 &kt_on MACRO_PLACEHOLDER>,
                <&macro_param_2to1 &kp MACRO_PLACEHOLDER>,
                <&macro_param_1to1 &sk MACRO_PLACEHOLDER>,
                <&macro_param_1to1 &kt_off MACRO_PLACEHOLDER>;
            label = "ALT_TAB";
        };
    };

    behaviors {
        kt_off: key_toggle_off_only {
            compatible = "zmk,behavior-key-toggle";
            #binding-cells = <1>;
            display-name = "Key Toggle Off";
            toggle-mode = "off";
        };
    };

    keymap {
        layer_0 {
            bindings = <
                &alt_tab LEFT_ALT TAB
            >;
        };
    };
};
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

作り方は簡単なので割愛する。

### 3. Layer-TapでAltを代用
- Layer-Tapの移動先レイヤでマクロを押すと`[Alt↓]` `[Tab↓↑]`
- 続けて押すと`[Tab↓↑]`
- Layer-Tapを離すと`[Alt↑]`

みたいな感じのもの。
Layer-Tapはどこかにあるだろうから実質1キー消費。レイヤー0のキー数消費に関しては実質0と言ってもいい。

私はさらに、TabとShift+Tabを並べ、Alt+TabとAlt+Shift+Tabができるようにした上で逆から押し始めたらCtrl+Tab, Ctrl+Shift+Tabとして動作するようにしている。

作り方はやや煩雑。

#### 作り方
1. [zmk-listeners](https://github.com/ssbb/zmk-listeners) を導入する
2. moのreleaseに`&to 0`を仕込んだマクロを作る
3. 上記moを使ったltを作り、レイヤー0に配置する
4. `&to ALT_TAB`と`&kp tab`をセットにしたマクロを作り、lt先のレイヤーに配置する
5. `ALT_TAB`レイヤーに`Tab`(と`Shift+Tab`)を配置する
6. zmk-listenersでALT_TABレイヤーの有効化時にAltを押し、無効化時に離す

```dts
#define ALT_TAB 5 // Alt-Tab用レイヤー
#define CTRL_TAB 6 // Ctrl-Tab用レイヤー

/ {
    layer_listeners {
        compatible = "zmk,layer-listeners";

        release_alt {
            layers = <ALT_TAB>;
            bindings = <&kt_on LEFT_ALT &kt_off LEFT_ALT>;
        };

        release_ctrl {
            layers = <CTRL_TAB>;
            bindings = <&kt_on LCTRL &kt_off LCTRL>;
        };
    };

    macros {
        to_kp: to_kp {
            compatible = "zmk,behavior-macro-two-param";
            #binding-cells = <2>;
            bindings = <&macro_param_1to1 &to MACRO_PLACEHOLDER &macro_param_2to1 &kp MACRO_PLACEHOLDER>;
            label = "to_kp";
        };

        mo_to_0: mo_to_0 {
            compatible = "zmk,behavior-macro-one-param";
            wait-ms = <0>;
            tap-ms = <0>;
            #binding-cells = <1>;
            bindings =

                <&macro_press>,
                <&macro_param_1to1 &mo MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&macro_pause_for_release>,
                <&macro_release>,
                <&macro_param_1to1 &mo MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&to 0>;

            label = "MO_to_0";
        };

        behaviors {
            kt_on: key_toggle_on_only {
                compatible = "zmk,behavior-key-toggle";
                #binding-cells = <1>;
                display-name = "Key Toggle On";
                toggle-mode = "on";
            };

            kt_off: key_toggle_off_only {
                compatible = "zmk,behavior-key-toggle";
                #binding-cells = <1>;
                display-name = "Key Toggle Off";
                toggle-mode = "off";
            };

            lt_to_0: lt_to_0 {
                compatible = "zmk,behavior-hold-tap";
                label = "LT_to_0";
                bindings = <&mo_to_0>, <&kp>;

                #binding-cells = <2>;
                tapping-term-ms = <200>;
                quick-tap-ms = <200>;
                flavor = "balanced";
            };
        };
    };

    keymap {
        layer_0 {
            bindings = <
                &lt_to_0 1 B
            >;
        };

        layer_1 {
            bindings = <
                &to_kp ALT_TAB TAB
                &to_kp CTRL_TAB TAB
            >;
        };

        ALT_TAB {
            bindings = <
                &kp TAB
                &kp LS(TAB)
            >;
        };

        CTRL_TAB {
            bindings = <
                &kp LS(TAB)
                &kp TAB
            >;
        };
    };
};
```

### 4. トラボでTabを代用
トラボの上下左右にキーを割り当てる機能で、右左にTab, Shift+Tabを当てる。
空いてる上下をCtrl+Tab, Ctrl+Shift+Tabに当てるのもアリ。

#### 作り方
方法3の実装を流用する。

TODO: トラボにキーを割り当てる機能の説明

## Auto Mouse Layer関連
トラボを動かすと一定時間だけマウスレイヤーが有効になるという機能。
このタイムアウトを使いこなすのは難しく、誤爆に悩まされる人が後を絶たない。

解決策としては、AMLを諦める(ltなどで手動でマウスレイヤーに移動するか、レイヤー0にマウスキーを配置する)か、マウスキーを押すまでマウスレイヤーに留まる(マウスキーを押したらマウスレイヤーを抜ける)ようにするという方法がとられている。

私の場合は、タイムアウトを無限(タイムアウトなし)にして、マウスレイヤーから戻るには必ずマウスキー以外を押すという設定にしている。
誤爆の原因はタイムアウトを脳が把握できないからであって、タイムアウトをなくすことが解決につながると理解している。
それには2つの方向があって、タイムアウトを0にするという方向だとAMLを諦めることになり、逆の方向に行くと、タイムアウトを無限にすることになるわけだ。

なお、ZMKのAMLの実装(正確には、ZMKで用意されている機能ではなく、zmk-pmw3610-driverで実装されている)はQMKよりも単純で、QMKの
- マウスキーを押したらタイムアウトを延長する
- マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける

という仕様がない。それ+マウスキーを押すまでマウスレイヤーに留まる機能をZMKでも求める人は少なくない。
これらはマクロで再現できる。

### 作り方
#### マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける
※[後述のInput Processorを使用する方法](#オートマウスレイヤー)でもおそらく再現可能。そっちの方が楽だと思われる。

マウスレイヤーを抜けるマクロ`exit_AML`を作り、それを仕込んだ`kp`、`mo`、`lt`をマクロとbehaviorで作る。
普段使用する`kp`、`mo`、`lt`をそれで置き換えたら完了。

なお、これを使うとQuick Tap(Hold-Tapにおいて、素早くダブルタップした後ホールドし続けるとタップの連打を発行する機能)が動作しない。
Quick Tapを使いたい場合は、ホールド時のみAML解除する`lt_exit_AML_on_hold`と`mt_exit_AML_on_tap`を作成して使用する。
```dts
#define MOUSE 4 // 各自のマウスレイヤーに合わせて設定

/{
    macros {
        exit_AML: exit_AML {
            compatible = "zmk,behavior-macro";
            wait-ms = <0>;
            tap-ms = <0>;
            #binding-cells = <0>;
            bindings = <&tog_off MOUSE>;
            label = "exit_AML";
        };

        kp_exit_AML: kp_exit_AML {
            compatible = "zmk,behavior-macro-one-param";
            wait-ms = <0>;
            tap-ms = <0>;
            #binding-cells = <1>;
            bindings = <&macro_param_1to1 &kp MACRO_PLACEHOLDER &exit_AML>;
            label = "KP_exit_AML";
        };

        mod_exit_AML: mod_exit_AML {
            compatible = "zmk,behavior-macro-one-param";
            wait-ms = <0>;
            tap-ms = <0>;
            #binding-cells = <1>;
            bindings =
                <&macro_press>,
                <&macro_param_1to1 &kp MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&exit_AML>,
                <&macro_pause_for_release>,
                <&macro_release>,
                <&macro_param_1to1 &kp MACRO_PLACEHOLDER>;

            label = "MOD_exit_AML";
        };

        mo_exit_AML: mo_exit_AML {
            compatible = "zmk,behavior-macro-one-param";
            wait-ms = <0>;
            tap-ms = <0>;
            #binding-cells = <1>;
            bindings =
                <&macro_press>,
                <&macro_param_1to1 &mo MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&exit_AML>,
                <&macro_pause_for_release>,
                <&macro_release>,
                <&macro_param_1to1 &mo MACRO_PLACEHOLDER>,
                <&macro_tap>;

            label = "MO_exit_AML";
        };
    };

    behaviors {
        tog_off: toggle_layer_off {
            compatible = "zmk,behavior-toggle-layer";
            #binding-cells = <1>;
            display-name = "Toggle Layer Off";
            toggle-mode = "off";
        };

        lt_exit_AML: lt_exit_AML {
            compatible = "zmk,behavior-hold-tap";
            label = "LT_exit_AML";
            bindings = <&mo_exit_AML>, <&kp_exit_AML>;

            #binding-cells = <2>;
            tapping-term-ms = <200>;
            quick-tap-ms = <200>;
            flavor = "balanced";
        };

        lt_exit_AML_on_hold: lt_exit_AML_on_hold {
            compatible = "zmk,behavior-hold-tap";
            label = "LT_exit_AML_ON_HOLD";
            bindings = <&mo_exit_AML>, <&kp>;

            #binding-cells = <2>;
            tapping-term-ms = <200>;
            quick-tap-ms = <200>;
            flavor = "balanced";
        };

        mt_exit_AML: mt_exit_AML {
            compatible = "zmk,behavior-hold-tap";
            label = "MT_exit_AML";
            bindings = <&mod_exit_AML>, <&kp_exit_AML>;

            #binding-cells = <2>;
            tapping-term-ms = <200>;
            flavor = "balanced";
            quick-tap-ms = <200>;
        };

        mt_exit_AML_on_tap: mt_exit_AML_on_tap {
            compatible = "zmk,behavior-hold-tap";
            label = "MT_exit_AML_ON_TAP";
            bindings = <&kp>, <&kp_exit_AML>;

            #binding-cells = <2>;
            tapping-term-ms = <200>;
            flavor = "balanced";
            quick-tap-ms = <200>;
        };
    };
}
```
#### マウスキーを押したらタイムアウトを延長する・マウスキーを押したらマウスレイヤーを抜ける
マウスキーを押したらマウスレイヤーを抜ける場合でも、ダブルクリックの猶予を与えるために一定時間待たなければならない。
そのため、実は「マウスキーを押したらタイムアウトを延長する」と「マウスキーを押すまでマウスレイヤーに留まる」は同じ実装で、タイムアウトの違いしかない。

具体的には、このマクロを`mkp`の代わりに使用すればよい。
マウスキーを押すまでマウスレイヤーに留まるなら、AMLのタイムアウトは長めにしておく。
```dts
#define MOUSE 4 // 各自のマウスレイヤーに合わせて設定

&sl { release-after-ms = <1000>; }; // タイムアウトを指定

/{
    macros {
        mkp_exit_AML: mkp_exit_AML {
            compatible = "zmk,behavior-macro-one-param";
            #binding-cells = <1>;
            bindings =
                <&macro_press>,
                <&macro_param_1to1 &mkp MACRO_PLACEHOLDER>,
                <&macro_pause_for_release>,
                <&macro_release>,
                <&macro_param_1to1 &mkp MACRO_PLACEHOLDER>,
                <&macro_tap>,
                <&sl MOUSE>;

            label = "MKP_EXIT_AML";
        };
    };
};
```

## Input Processorあれこれ
可変CPI、スクロールレイヤー、オートマウスレイヤーといったPMW3610ドライバーで用意されている機能は、後からZMKに追加されたInput Processorでも設定可能。
スクロールレイヤーやAMLは若干挙動が異なるので、人によってはInput Processorを使う方が好みかもしれない。
特にAMLの方は非マウスキーを押すと自動でAML解除してくれるが、これはPMW3610ドライバーにはない仕様。

### 低CPI/高CPIモード
roBa_R.overlayに以下を追記すると、レイヤー2ではカーソル移動量3分の1、レイヤー3では3倍になる。
```dts
#include <input/processors.dtsi>
/ {
    trackball_listener {
        compatible = "zmk,input-listener";
        device = <&trackball>;

        cpi-low {
            layers = <2>;
            input-processors = <&zip_xy_scaler 1 3>;
        };

        cpi-high {
            layers = <3>;
            input-processors = <&zip_xy_scaler 3 1>;
        };
    };
};
```

zmk-pmw3610-driverのsnipe-layersを使う手もある。こっちだとデフォルトと別CPIの2パターンだけになってしまうが、大抵はそれで充分。

### スクロールレイヤー
roBa_R.overlayに以下を追記すると、レイヤー4ではカーソル移動がスクロールに変換される。
自分の試したところ、y方向のスクロールが逆になったので`&zip_xy_transform`で反転させている。
スクロール量が多すぎるor少なすぎる場合は、`&zip_xy_scaler`の部分をコメントアウトして調整できる。
```dts
#include <input/processors.dtsi>
#include <dt-bindings/zmk/input_transform.h>
/ {
    trackball_listener {
        compatible = "zmk,input-listener";
        device = <&trackball>;

        scroller {
            layers = <4>;
            input-processors =
                // <&zip_xy_scaler 3 2>,
                <&zip_xy_transform INPUT_TRANSFORM_Y_INVERT>,
                <&zip_xy_to_scroll_mapper>;
        };
    };
};
```

### オートマウスレイヤー
roBa_R.overlayに以下を追記すると、トラボ使用後10秒間、レイヤー5が有効になる。
非マウスキーを押すと自動でAML解除してくれるが、これはPMW3610ドライバーにはない仕様。
`&zip_temp_layer`を再定義すると、マウスキー以外にも任意のキー位置をAML解除対象外に設定できる。
```dts
#include <input/processors.dtsi>
/ {
    trackball_listener {
        compatible = "zmk,input-listener";
        device = <&trackball>;

        input-processors = <&zip_temp_layer 5 10000>;
    };
};
```
