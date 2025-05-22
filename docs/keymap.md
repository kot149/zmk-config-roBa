# キーマップ
備忘録を兼ねて、キーマップについて語りつつ、その設定方法を紹介する。

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
`sl_250`の`release-after-ms`を変更すると、タイムアウト時間を変更できる。
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
## Auto Mouse Layer(AML)関連
トラボを動かすと一定時間だけマウスレイヤーが有効になるという機能。

roBaやmoNaのデフォルトのconfigでは、zmk-pmw3610-driverのAML機能を使用している。
zmk-pmw3610-driverで実装されているAMLはQMKよりも単純で、QMKの

- マウスキーを押したらタイムアウトを延長する
- マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける

という仕様がない。これらはZMKのInput Processorまたはマクロで解決できる。

また、AML誤爆対策の一つとして、マウスキーを押すまでマウスレイヤーに留まる(マウスキーを押したらマウスレイヤーを抜ける)ようにするという方法が存在する。
これはマクロとレイヤー移動の組み合わせで作成できる。

### 作り方
#### マウスキー以外を押したらタイムアウト関係なしにマウスレイヤーを抜ける
※[後述のInput Processorを使用する方法](#オートマウスレイヤー) を参照。

<details>
<summary style="font-weight: bold;">マクロで再現する方法</summary>

Input Processerを使わなくても、マクロで再現することができる。

だいたいはInput Processorで十分だが、「`lt`や`mt`のホールド/タップのどちらかのみAMLを解除/維持したい」という場合には、Input Processorでは対応できない。
そうしたい具体的なケースとしては、Shift+クリックがある。これはタップ時のみAML解除しホールド時はAML維持するようにしなければ、Shiftをホールドした後に一度カーソルを動かしてからクリックしないといけなくなる。

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
</details>

#### マウスキーを押したらタイムアウトを延長する・マウスキーを押したらマウスレイヤーを抜ける
[後述のInput Processorを使用する方法](#マウスキー押下でタイムアウトを延長する) を参照。

なお、マウスキーを押したらマウスレイヤーを抜ける場合でも、ダブルクリックの猶予を与えるために一定時間待たなければならない。
そのため、実は「マウスキーを押したらタイムアウトを延長する」と「マウスキーを押すまでマウスレイヤーに留まる」は同じ実装で、タイムアウトの違いしかない。

<details>
<summary style="font-weight: bold;">マクロで再現する方法</summary>

このマクロを`mkp`の代わりに使用することでも再現できる。
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
</details>

## Input Processorあれこれ
可変CPI、スクロールレイヤー、オートマウスレイヤーといったzmk-pmw3610-driverで用意されている機能は、後からZMKに追加されたInput Processorでも設定可能。
スクロールレイヤーやAMLは若干挙動が異なるので、人によってはInput Processorを使う方が好みかもしれない。
特にAMLの方はキー押下ででAML解除してくれる機能を設定できるが、これはzmk-pmw3610-driverにはない仕様。

### 低CPI/高CPIモード
`roBa_R.overlay`に以下を追記すると、レイヤー2ではカーソル移動量3分の1、レイヤー3では3倍になる。
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

zmk-pmw3610-driverの`snipe-layers`を使う手もある。こっちだとデフォルトと別CPIの2パターンだけになってしまうが、大抵はそれで充分。

### スクロールレイヤー
`roBa_R.overlay`に以下を追記すると、レイヤー4ではカーソル移動がスクロールに変換される。
自分の試したところ、y方向のスクロールが逆になったので`&zip_xy_transform`で反転させている。
スクロール量が多すぎるor少なすぎる場合は、`&zip_xy_scaler`の部分をコメント解除して調整できる。
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
トラボを動かすと一定時間だけマウスレイヤーが有効になるという機能。
zmk-pmw3610-driverで用意されていた機能だが、後に追加されたInput Processorでも設定可能。

Input Processorを使用した方法では、`excluded-positions`を設定すると、そのキー以外の押下時にAML解除される。これはzmk-pmw3610-driverのAMLにはない仕様。

ただし、注意点がいくつかある。
- 「マウスキーかそれ以外か」ではなく、「`excluded-positions`で設定したキーかそれ以外か」なので、QMK(Keyball)から来た人は混乱しやすい
- `excluded-positions`を設定しなければ、「どのキーを押してもAMLが**解除されない**」。この仕様はちょっと分かりづらい
- `excluded-positions`を押下しても、タイムアウトの延長はしてくれない。これをやるには、`&mkp`に対してInput Processorを設定する。

Input Processorを使用する場合は、zmk-pmw3610-driverのAMLは無効化しておくこと。具体的には、`roBa_R.overlay`の`automouse-layer = <...>;`を消しておく。

#### `excluded-positions`を使用しない例
`roBa_R.overlay`に以下を追記すると、トラボ使用後10秒間、レイヤー5が有効になる。
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

#### `excluded-positions`を使用する例
`roBa_R.overlay`に以下を追記すると、トラボ使用後10秒間、レイヤー5が有効になる。
`excluded-positions`以外のキーを押すとAMLが解除される。
ここでは、`J`, `K`, `;`, `Z`(`Shift`), `Ctrl`の位置を`excluded-positions`に設定している。
```dts
#include <input/processors.dtsi>
/ {
    /omit-if-no-ref/ zip_temp_layer: zip_temp_layer {
        compatible = "zmk,input-processor-temp-layer";
        #input-processor-cells = <2>;
        excluded-positions = <
            18 // J
            19 // K
            21 // ;
            22 // Z
            34 // Ctrl
        >;
    };

    trackball_listener {
        compatible = "zmk,input-listener";
        device = <&trackball>;

        input-processors = <&zip_temp_layer 5 10000>;
    };
};
```

#### マウスキーを押したらタイムアウトを延長する・マウスキーを押したらマウスレイヤーを抜ける
`&mkp`に対してInput Processorを設定することで、マウスキーを押したらタイムアウトを延長する・マウスキーを押したらマウスレイヤーを抜ける機能を実現できる。
`roBa_L.keymap`に以下を追記すると、クリックしたときに10秒間レイヤー5が有効になる。
```dts
#include <input/processors.dtsi>

&mkp_input_listener {
    input-processors = <&zip_temp_layer 5 10000>;
};
```

## トラボで矢印キー入力
トラボの上下左右操作にキーを割り当てる機能が[kumamuk-git/zmk-pmw3610-driver](https://github.com/kumamuk-git/zmk-pmw3610-driver) には実装されている(私がプルリクしました)。

### 単純なキー割り当て
単純に矢印キーなどを割り当てるだけなら、`roBa_R.overlay`に記述するだけで済む。
```dts
#include <dt-bindings/zmk/keys.h>

&spi0 {
    ...

    trackball: trackball@0 {
        ...

        arrows {
            layers = <3>;
            bindings =
                <&kp RIGHT_ARROW>,
                <&kp LEFT_ARROW>,
                <&kp UP_ARROW>,
                <&kp DOWN_ARROW>;

            /*   optional: ball action configuration  */
            tick = <10>;
            // wait-ms = <5>;
            // tap-ms = <5>;
        };
    };
};
```

### マクロの割り当て
マクロは`roBa.keymap`に記述されているので、そのままでは`roBa_R.overlay`から参照できない。

それを可能にするには、`roBa.keymap`で`roBa_R.overlay`をincludeし、`&trackball`を参照できるようにすることで、keymap側からトラボの設定をする。
ただし、それをやると左手側のビルドが通らなくなってしまう。
これを解決するには、左右でキーマップを分ける必要がある。具体的には、
1. `roBa.keymap`を`roBa_L.keymap`にリネームする
2. `roBa_R.keymap`を作成し、`roBa_L.keymap`をincludeする
3. `roBa_R.keymap`に`&trackball`の設定を記述する

これで左右のビルドが通るようになる。

<details>
<summary style="font-weight: bold;">キーマップファイルのファイル名に関する仕様</summary>

keymapファイルの名前解決手順は、例えば`roBa_R`のビルドの場合、
1. `roBa.keymap`を探す
2. 見つからない場合は`roBa_R.keymap`を探す
3. それも見つからない場合はエラー

となっている模様。
このため、`roBa.keymap`と`roBa_R.keymap`の2ファイル構成にしようと思うと、先に`roBa_R.keymap`が読まれてしまい、トラボの設定が無効になってしまう。
また、`roBa_right.keymap`のような名前にすることもできない。
</details>

なお、`roBa_L.keymap`をインクルードしているので、トラボの依存しない設定は`roBa_L.keymap`だけ書き換えれば右手側にも反映される。
[Keymap Editor](https://nickcoutsos.github.io/keymap-editor/) は複数キーマップをサポートしており、画面上部で編集するキーマップを選択できる。
デフォルトで選択されるキーマップはおそらくアルファベット順で早い方で、`roBa_L.keymap`が選択されるので、特に意識することなく使用できる。

## マウスカーソルのポーリングレート

### Bluetoothの通信間隔
`roBa_R.conf`の以下をパラメーターでPCとの通信間隔？を設定できる。これにより、マウスカーソルのポーリングレートが向上する。

デフォルトはMIN`24`、MAX`40`。値は`6`～`3199`の値で設定する。単位は1.25ms。

```dts
CONFIG_BT_PERIPHERAL_PREF_MIN_INT=12
CONFIG_BT_PERIPHERAL_PREF_MAX_INT=12
```

- `6`なら7.5ms/回、133.33Hz
- `12`なら15ms/回、66.66Hz
- `24`なら30ms/回、33.33Hz

という計算。

公式ドキュメント:
- [CONFIG_BT_PERIPHERAL_PREF_MIN_INT](https://docs.nordicsemi.com/bundle/ncs-1.8.0/page/kconfig/CONFIG_BT_PERIPHERAL_PREF_MIN_INT.html)
- [CONFIG_BT_PERIPHERAL_PREF_MAX_INT](https://docs.nordicsemi.com/bundle/ncs-1.8.0/page/kconfig/CONFIG_BT_PERIPHERAL_PREF_MAX_INT.html)

### PMW3610のポーリングレート
また、PMW3610(トラックボールセンサー)のポーリングレートを変更できる。`roBa_R.conf`で以下をいずれかを設定する。
```dts
CONFIG_PMW3610_POLLING_RATE_125=y      # 125Hz
CONFIG_PMW3610_POLLING_RATE_125_SW=y   # ハードは250Hz動作、ソフトで125Hzで制御
CONFIG_PMW3610_POLLING_RATE_250=y      # 250Hz
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
方法3の実装を流用する。トラボへのマクロ割り当ては[こちら](#マクロの割り当て) を参照。
