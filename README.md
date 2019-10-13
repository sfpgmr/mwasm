# mwasm

## 概要

Web Asesembly Text Format （S式）用のプリプロセッサです。

定数式はJavaScriptの構文を採用し、アセンブラでいうところのマクロ機能の一部を実現します。

## 動機

wasmのテキスト・モード(wat)でコードを書こうしたときに、定数ラベルや定数式を処理できれば楽にコーディングできるのではないかと考えたことがきっかけです。

## 実装について

構文パーサはpeg\.jsを使用しています。
プリプロセスを実行する部分はnode.jsを使用しており、プリプロセス後のソースコードをwabtに引き渡し、wasmバイナリ化しています。

## インストール方法

1. `git clone`します。
2. クローンしたディレクトリにて `npm install`を実行します。
3. cliを使用する場合はさらに`npm install -g`します。

## 状態

作成中の状態です。wsl上でのみ実行できることを確認しています。node.js環境で動作します。
自分用に作成しているので、エラー処理などかなりいい加減なものになっていますのでご注意ください。

## サンプルの実行

`npm run test`でテストが走ります。

## コマンドライン

bin/mwasm コマンドで実行します。

mwasm ソーステキスト名 [-o wasmバイナリ出力ファイル名]

-oを指定しない場合はコンソールにプリプロセス後のソースコードを表示します。

## プリプロセッサの構文について

### { JSステートメントブロック }

JSステートメントをプリプロセス時に実行します。結果をreturnで返すとその位置に値が埋め込まれます。
コンテキストオブジェクトとして`$`が用意されており、コードブロック内で書き込み・参照が可能です。
ローカル変数なども定義できますが、コードブロック中でのみ有効です。

```
{
  // JSによるWASMソースコード生成
  let instructions = '';
  for(let i = 0;i < 4; ++ i ){
    ++$.X; 
    instructions += `
  i32.const ${$.X + $.Y}
  i32.add`;
  }
  return instructions;
}
```

### {@ JSステートメントブロック } 

JSステートメントをプロプロセス時に実行しますが値を埋め込みません。

```
{@
// コンテキスト$ にプロパティを設定する
$.X = 0x1;
$.Y = 2;
$.Z = 0x3;
}
```


### {$ JS式}

JS式を実行し、結果をその位置に埋め込みます。

```
i32.const {$ $.X + $.Y }
```
### {$.プロパティ式}

プロパティ式を実行し、結果をその位置に埋め込みます。

```
i32.const {$.X + 1}
```

### {@struct}

構造体を定義します。

### {@map}

リニアメモリ中のメモリ配置を定義します。定義にには{@struct}で定義した構造体も型として使用できます。
```
{@struct A 
  i32 a;
}

{@struct B 
  i32 b;
  A a;
}
{@struct C 
  i32 c;
  B b;
}


{@
// ローカル変数の定義
$.X = 1;
}

{@map 
  C c[10];
}
(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (i32.add 
    (i32.load (&c[0].b.a.a;))
    (&c[0].c;)
  )
)
)
```
### &メモリ・マップor構造体指定式; 

メモリオフセットを計算し、i32のconst値として展開します。

```
{@map
  i32 a;
  i32 b;
}

(&b;) ;;(i32.const 4)

```

構造体定義名を指定した場合は、先頭のオフセットを0とした場合のオフセットを返します。
```
{@struct C
  i32 a;
  i32 b;
}

(#C;);; (i32.const 8)

```

### \#メモリ・マップor構造体指定式; 

構造体の大きさを計算し、i32のconst値として展開します。

```
{@struct C
  i32 a;
  i32 b;
}

{@map
  C c;
}

(#c;);; (i32.const 8)
(#C;);; (i32.const 8)
```

### %プロパティ式;

JSで定義した定数を展開します。

```
{@
$.INDEX = 1;
}

(i32.const %INDEX;) ;; (i32.const 1)
(i32.const %INDEX + 1;) ;; (i32.const 2)

```
### {@macro_def} / {@end_macro_def} 

マクロを定義します。定義したマクロは`{@@マクロ名 パラメータ,パラメータ... }`で使用できます。

```
{@macro_def t(a)}
(i32.const a)
{@end_macro_def}

{@macro_def offset (a,b)}
(a.add 
  (a.const 10)
  {@@t b}
)
{@end_macro_def}

{@macro_def macro_fp(b)}
(f32.add
  b
  (f32.const 0.5)
)
{@end_macro_def}

{@map
  i32 test_offset;
}

(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (local $a i32)
  {@@offset i32,0x0001}
)
(func $testfp (result f32)
  {@@macro_fp
    (f32.const 1)
  }
)
)
```

### {@include JS式}

JS式の結果得られるpathにあるファイルをインクルードします。

```
{@include './test_inc.mwat'}
```

### {@if JS式}　ソース１ [{@else} ソース２] {@endif}

JS式が真の場合ソース1を埋め込み、そうでない場合はソース2を埋め込みます。
`@else ソース2`は省略可能です。

```
{@if $.X < 1}

...ソース1

{@else}

...ソース2

{@endif}

```

## 開発について

* パッケージのバンドルには[rollup](https://rollupjs.org/guide/en)を使用しています。
* 構文パーサは[peg.js](https://pegjs.org/)を使用しております。

## 実装例

```
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mwasm サンプルコード
;; PSG エミュレータ
;;
;; 以下のコード参考にをWebAssembly化してみた
;; https://github.com/digital-sound-antiques/emu2149
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
{@
  ;; 定数定義 ;;
  $.GETA_BITS = 24;
  $.EMU2149_VOL_YM2149 = 0;
  $.EMU2149_VOL_AY_3_8910 = 1;
  $.EMU2149_VOL_DEFAULT  =  $.EMU2149_VOL_AY_3_8910;
  $.SHIFT_BITS = 1 << $.GETA_BITS;
  $.SHIFT_BITS_MASK = (1 << $.GETA_BITS) - 1;
  $.REG_MAX = 16;
}

;; 構造体 定義;;
{@struct PSG
i32 regmsk[REG_MAX] = [
    0xff, 0x0f, 0xff, 0x0f, 0xff, 0x0f, 0x1f, 0x3f,
    0x1f, 0x1f, 0x1f, 0xff, 0xff, 0x0f, 0xff, 0xff
];
    (;; Volume Table ;;)
    i32 voltbl_[64] = [ 0 , 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x05, 0x06, 0x07, 0x09,
   0x0B, 0x0D, 0x0F, 0x12, 0x16, 0x1A, 0x1F, 0x25, 0x2D, 0x35, 0x3F, 0x4C,
   0x5A, 0x6A, 0x7F, 0x97, 0xB4, 0xD6, 0xFF, 0xFF, 0x00, 0x00, 0x01, 0x01,
   0x02, 0x02, 0x03, 0x03, 0x05, 0x05, 0x07, 0x07, 0x0B, 0x0B, 0x0F, 0x0F,
   0x16, 0x16, 0x1F, 0x1F, 0x2D, 0x2D, 0x3F, 0x3F, 0x5A, 0x5A, 0x7F, 0x7F,
   0xB4, 0xB4, 0xFF, 0xFF];
    i32 reg[REG_MAX];
    i32 voltbl;
    i32 out;

    i32 clk, rate, base_incr, quality;

    i32 count[3];
    i32 volume[3];
    i32 freq[3];
    i32 edge[3];
    i32 tmask[3];
    i32 nmask[3];
    i32 mask;

    i32 base_count;

    i32 env_volume;
    i32 env_ptr;
    i32 env_face;

    i32 env_continue;
    i32 env_attack;
    i32 env_alternate;
    i32 env_hold;
    i32 env_pause;
    i32 env_reset;

    i32 env_freq;
    i32 env_count;

    i32 noise_seed;
    i32 noise_count;
    i32 noise_freq;

    (;; rate converter ;;)
    i32 realstep;
    i32 psgtime;
    i32 psgstep;

    (;; I/O Ctrl ;;)
    i32 adr;

    (;; output of channels ;;)
    i32 ch_out[3];


}

;; リニアメモリ配置定義
{@map offset 0x1000;
  PSG psg;
  f32 OutputBuffer[128];
}


(module
  (export "setQuality" (func $set_quality))
  (export "setRate" (func $set_rate))
  (export "init" (func $init))
  (export "setVolumeMode" (func $set_volume_mode))
  (export "setMask" (func $set_mask))
  (export "toggleMask" (func $toggle_mask))
  (export "readIo" (func $read_io))
  (export "readReg" (func $read_reg))
  (export "writeIo" (func $write_io))
  (export "updateOutput" (func $update_output))
  (export "mixOutput" (func $mix_output))
  (export "calc" (func $calc))
  (export "reset" (func $reset))
  (export "writeReg" (func $write_reg))
  (export "memory" (memory $memory))
  (memory $memory 1 )
  (func $internal_refresh
     (i32.store (i32.const 0 ) (i32.load (&PSG.clk;)))
     (if
      ;; condition
      (i32.load (&psg.quality;))
      (then 
        (i32.store (&psg.base_incr;) (i32.const {$ 1 << $.GETA_BITS}))
        (i32.store 
          (&psg.realstep;)
          (i32.div_u 
            (i32.const {$ 1 << 31})
            (i32.load (&psg.rate;))
          ) 
        )
        (i32.store
          (&psg.psgstep;)
          (i32.div_u
            (i32.const {$ 1 << 31})
            (i32.shr_u (i32.load (&psg.clk;)) (i32.const 4))
          )
        )
        (i32.store (&psg.psgtime;) (i32.const 0))
      )
      (else
        (i32.store
          (&psg.base_incr;)
          (i32.trunc_f64_u 
            (f64.div 
              (f64.mul 
                (f64.convert_i32_u (i32.load (&psg.clk;)))
                (f64.const {$ 1 << $.GETA_BITS})
              )
              (f64.mul
                (f64.convert_i32_u (i32.load (&psg.rate;)))
                (f64.const 16)
              )
            )
          )
        )
      )

    )
  )

  (func $set_rate (param $r i32) 
    (i32.store (&psg.rate;) 
     (select (local.get $r) (i32.const 44100) (local.get $r))
    )
    (call $internal_refresh)
  )

  
  (func $set_quality (param $q i32)
    (i32.store 
      (&psg.quality;)
      (local.get $q)
    )
    (call $internal_refresh)
  )

  (func $init (param $c i32) (param $r i32)
    (call $set_volume_mode (i32.const {$.EMU2149_VOL_DEFAULT}))
    (i32.store (&psg.clk;) (local.get $c))
    (i32.store 
      (&psg.rate;)
      (select
        (i32.const 44100)
        (local.get $r)
        (i32.eqz (local.get $r))
      )
    )
    (call $set_quality (i32.const 0))
  )
  
  (func $set_volume_mode (param $type i32)
    (i32.store 
      (&psg.voltbl;) 
      (i32.add 
        (&psg.voltbl_;) 
        (i32.shl (local.get $type) (@psg.voltbl + 5;))
      )
    )
  )

  (func $set_mask (param $mask i32) (result i32)
    (i32.load (&psg.mask;))
    (i32.store (&psg.mask;) (local.get $mask))
  )

  (func $toggle_mask (param $mask i32) (result i32)
    (i32.load (&psg.mask;))
    (i32.store (&psg.mask;)
      (i32.xor (i32.load (&psg.mask;)) (i32.const 0xffff_ffff))
    )
  )

  (func $reset
    (local $c i32)
    (local $work i32)
    (local $size i32)
    (local $count i32)
    (local $freq i32)
    (local $edge i32)
    (local $volume i32)
    (local $ch_out i32)

    (local.set $count (&psg.count;))
    (local.set $freq (&psg.freq;))
    (local.set $edge (&psg.edge;))
    (local.set $volume (&psg.volume;))
    (local.set $ch_out (&psg.ch_out;))

    (i32.store (&psg.base_count;) (i32.const 0))
    (local.set $c (i32.const 3))

    (block $exit
      (loop $loop
        (br_if $exit (i32.eqz (local.get $c)))
        (local.set $c (i32.sub (local.get $c) (i32.const 1)))
        (i32.store (local.get $count) (i32.const 0x1000))
        (i32.store (local.get $freq) (i32.const 0))
        (i32.store (local.get $edge) (i32.const 0))
        (i32.store (local.get $volume) (i32.const 0))
        (i32.store (local.get $ch_out) (i32.const 0))
        (local.set $count (i32.add (local.get $count) (#psg.count;)))
        (local.set $freq (i32.add (local.get $freq) (#psg.freq;)))
        (local.set $edge (i32.add (local.get $edge) (#psg.edge;)))
        (local.set $volume (i32.add (local.get $volume) (#psg.volume;)))
        (local.set $ch_out (i32.add (local.get $ch_out) (#psg.ch_out;)))
        (br $loop)
      )
    )
    
    (i32.store (&psg.mask;) (i32.const 0))

    ;; レジスタの初期化
    (local.set $c (i32.const 16))
    (local.set $work (&psg.reg;))
    (block $exit_reg
      (loop $loop_reg
        (br_if $exit_reg (i32.eqz(local.get $c) ))
        (local.set $c (i32.sub (local.get $c) (i32.const 1)))
        (i32.store (local.get $work) (i32.const 0))
        (local.set $work (i32.add (local.get $work) (#psg.reg;)) )
        (br $loop_reg)
      )
    )

    (i32.store (&psg.adr;) (i32.const 0))
    (i32.store (&psg.noise_seed;) (i32.const 0xffff))
    (i32.store (&psg.noise_count;) (i32.const 0x40))
    (i32.store (&psg.noise_freq;) (i32.const 0))

    (i32.store (&psg.env_volume;) (i32.const 0))
    (i32.store (&psg.env_ptr;) (i32.const 0))
    (i32.store (&psg.env_freq;) (i32.const 0))
    (i32.store (&psg.env_count;) (i32.const 0))
    (i32.store (&psg.env_pause;) (i32.const 1))

    (i32.store (&psg.out;) (i32.const 0))

  )

  (func $read_io (result i32)
    (i32.load
      (i32.add 
        (&psg.reg;)
        (i32.shl (i32.load (&psg.adr;)) (i32.const {$ Math.log2($.psg.adr[$attributes].size) | 0 }))
      ) 
    )
  )
  (func $read_reg (param $reg i32) (result i32)
    (i32.load
      (i32.add 
        (&psg.reg;)
        (i32.shl (local.get $reg) (@psg.reg;))      
      )
    )
  )
  
  (func $write_io (param $adr i32) (param $val i32)
    (if 
      (i32.and (local.get $adr) (i32.const 1))
      (then
        (call $write_reg (i32.load (&psg.adr;)) (local.get $val))
      )
      (else
        (i32.store (&psg.adr;) (i32.and (local.get $val) (i32.const 0x1f))) 
      )
    )
  )

  (func $update_output 
    (local $incr i32)
    (local $noise i32)
    (local $i i32)
    (local $offset i32)

    (i32.store (&psg.base_count;) 
      (i32.add 
        (i32.load (&psg.base_count;))
        (i32.load (&psg.base_incr;))
      )
    )
    (local.set $incr (i32.shr_u (i32.load (&psg.base_count;)) (i32.const {$.GETA_BITS})))
    (i32.store 
      (&psg.base_count;)
      (i32.and 
        (i32.load(&psg.base_count;))
        (i32.const {$.SHIFT_BITS_MASK})
      )
    )

    ;; Envelope
    (i32.store 
      (&psg.env_count;)
      (i32.add 
        (i32.load (&psg.env_count;)) 
        (local.get $incr)
      )
    )
    
    (block $exit_envelope
      (loop $loop_envelope
        (br_if $exit_envelope
          (i32.or 
            (i32.lt_u (i32.load (&psg.env_count;)) (i32.const 0x10000))
            (i32.eqz (i32.load (&psg.env_freq;) ))
          )
        )
        (if (i32.eqz (i32.load (&psg.env_pause;)))
          (then
            (if (i32.load (&psg.env_face;))
              (then
                (i32.store 
                  (&psg.env_ptr;)
                  (i32.and 
                    (i32.add
                      (i32.load (&psg.env_ptr;))
                      (i32.const 1)
                    )
                    (i32.const 0x3f)
                  )
                )
              )
              (else
                (i32.store 
                  (&psg.env_ptr;)
                  (i32.and 
                    (i32.add
                      (i32.load (&psg.env_ptr;))
                      (i32.const 0x3f)
                    )
                    (i32.const 0x3f)
                  )
                )
              
              )
            )
          )
        )

        (if
          (i32.and (i32.load (&psg.env_ptr;)) (i32.const 0x20))
          (then
            (if 
              (i32.load (&psg.env_continue;))
              (then
                (if
                  (i32.xor 
                    (i32.load (&psg.env_alternate;))
                    (i32.load (&psg.env_hold;))
                  )
                  (then
                    (i32.store (&psg.env_face;)
                      (i32.xor
                        (i32.load (&psg.env_face;))
                        (i32.const 1)
                      )
                    )
                  )
                )
                (if
                  (i32.load (&psg.env_hold;))
                  (then
                    (i32.store (&psg.env_pause;) (i32.const 1))
                  )
                )
                (i32.store 
                  (&psg.env_ptr;)
                  (select
                    (i32.const 0)
                    (i32.const 0x1f)
                    (i32.load (&psg.env_face;))
                  )
                )
              )
              (else
                (i32.store (&psg.env_pause;) (i32.const 1))
                (i32.store (&psg.env_ptr;) (i32.const 0))
              )
            )
          )
        )
        (i32.store
          (&psg.env_count;)
          (i32.sub
            (i32.load (&psg.env_count;)) 
            (i32.load (&psg.env_freq;)) 
          ) 
        ) 
        (br $loop_envelope)
      )
    )

    ;; Noise
    (i32.store 
      (&psg.noise_count;)
      (i32.add
        (i32.load (&psg.noise_count;))
        (local.get $incr)
      )
    )
    (if
      (i32.and (i32.load (&psg.noise_count;)) (i32.const 0x40))
      (then
        (if
          (i32.and 
            (i32.load (&psg.noise_seed;))
            (i32.const 1)
          )
          (then
            (i32.store
              (&psg.noise_seed;)
              (i32.xor 
                (i32.load (&psg.noise_seed;))
                (i32.const 0x24000)
              )
            )
          )
        )
        (i32.store 
            (&psg.noise_seed;)
            (i32.shr_u 
              (i32.load (&psg.noise_seed;))
              (i32.const 1)
            )
        )
        (i32.store
          (&psg.noise_count;)
          (i32.sub 
            (i32.load (&psg.noise_count;))
            (select 
              (i32.load (&psg.noise_freq;))
              (i32.const 2)
              (i32.load (&psg.noise_freq;))
            )
          )
        )
      )
    )
    
    (local.set $noise
      (i32.and 
        (i32.load (&psg.noise_seed;))
        (i32.const 1)
      )
    )

    ;; Tone
    (local.set $i (i32.const 3))
    (block $tone_exit
      (loop $tone_loop
        (br_if $tone_exit (i32.eqz (local.get $i)))
        (local.set $i
          (i32.sub (local.get $i) (i32.const 1))
        )

        (local.set $offset
            (i32.shl
              (local.get $i)
              (i32.const 2)
            )
        )
       (i32.store 
          (i32.add 
            (&psg.count;)
            (local.get $offset)
          )
          (i32.add
            (i32.load
              (i32.add 
                (&psg.count;)
                (local.get $offset)
              ) 
            )
            (local.get $incr)
          )
        )
        (if
          (i32.and 
            (i32.load
              (i32.add 
                (&psg.count;)
                (local.get $offset)
              )
            )
            (i32.const 0x1000)
          )
          (then
            (if
              (i32.gt_u
                (i32.load
                  (i32.add 
                    (&psg.freq;)
                    (local.get $offset)
                  )
                )
                (i32.const 1)
              )
              (then
                (i32.store
                  (i32.add 
                    (&psg.edge;)
                    (local.get $offset)
                  )
                  (i32.xor
                    (i32.load
                      (i32.add 
                        (&psg.edge;)
                        (local.get $offset)
                      )
                    )
                    (i32.const 0x1 )
                  )
                )
                (i32.store
                  (i32.add 
                    (&psg.count;)
                    (local.get $offset)
                  )
                  (i32.sub
                    (i32.load
                      (i32.add 
                        (&psg.count;)
                        (local.get $offset)
                      )
                    )
                    (i32.load
                      (i32.add 
                        (&psg.freq;)
                        (local.get $offset)
                      )
                    )
                  )
                )
              )
              (else
                (i32.store
                  (i32.add 
                    (&psg.edge;)
                    (local.get $offset)
                  )
                  (i32.const 1)

                )
              )
            )
          )
        )


        
       
        (if
          (i32.and
            (select (i32.const 1) (i32.const 0) 
              (i32.or
                (i32.load (i32.add (&psg.tmask;) (local.get $offset)))
                (i32.load (i32.add (&psg.edge;) (local.get $offset)))
              )
            )
            (select (i32.const 1) (i32.const 0)
              (i32.or
                (i32.load (i32.add (&psg.nmask;) (local.get $offset)))
                (local.get $noise)
              )
            )
          )
          (then
            (if
              (i32.eqz 
                (i32.and
                  (i32.load
                    (i32.add 
                      (&psg.volume;)
                      (local.get $offset)
                    )
                  )
                  (i32.const 32)
                )
              )
              (then
                (i32.store
                  (i32.add
                    (&psg.ch_out;)
                    (local.get $offset)
                  )
                  (i32.add
                    (i32.load 
                      (i32.add
                        (&psg.ch_out;)
                        (local.get $offset)
                      )
                    )
                    (i32.shl
                      (i32.load
                        (i32.add
                          (i32.load (&psg.voltbl;))
                          (i32.shl
                            (i32.and 
                              (i32.load
                                (i32.add
                                  (&psg.volume;)
                                  (local.get $offset)
                                )
                              )
                              (i32.const 31)
                            )
                            (@psg.voltbl;)
                          )
                        )
                      )
                      (i32.const 4)
                    )
                  )
                )  
              )
              (else
                (i32.store
                  (i32.add
                    (&psg.ch_out;)
                    (local.get $offset)
                  )
                  (i32.add
                    (i32.load
                      (i32.add
                        (&psg.ch_out;)
                        (local.get $offset)
                      )
                    )
                    (i32.shl
                      (i32.load
                        (i32.add 
                          (i32.load (&psg.voltbl;))
                          (i32.shl 
                            (i32.load (&psg.env_ptr;))
                            (@psg.voltbl_;)
                          )
                        )
                      )
                      (i32.const 4)
                    )
                  )
                )
              )
            )
          )

        )

        (i32.store 
          (i32.add
            (&psg.ch_out;)
            (local.get $offset)
          )
          (i32.shr_u
            (i32.load
              (i32.add
                (&psg.ch_out;)
                (local.get $offset)
              )
            )
            (i32.const 1)
          )
        )
        (br $tone_loop)
      )
    )
  )

  (func $mix_output (result i32)
    (i32.store
      (&psg.out;)
      (i32.add
        (i32.load (&psg.ch_out;))
        (i32.add
          (i32.load (&psg.ch_out[1];))
          (i32.load (&psg.ch_out[2];))
        )
      )
    )
    (i32.load (&psg.out;))
  )

  (func $calc (result i32)
    (if (i32.eqz (i32.load (&psg.quality;)))
      (then
        call $update_output
        call $mix_output
        return
      )
    )
    (block $rate_loop_exit
      (loop $rate_loop
        (br_if $rate_loop_exit 
          (i32.le_u (i32.load(&psg.realstep;)) (i32.load(&psg.psgtime;)))
        )
        (i32.store
          (&psg.psgtime;)
          (i32.add
            (i32.load(&psg.psgtime;))
            (i32.load(&psg.psgstep;))
          )
        )
        call $update_output
        (br $rate_loop)
      )
    )
    (i32.store
      (&psg.psgtime;)
      (i32.sub
        (i32.load(&psg.psgtime;))
        (i32.load(&psg.realstep;))
      )
    )

    call $mix_output
  )



  (func $write_reg (param $reg i32) (param $val i32) (local $c i32) (local $w i32)
    (if (i32.gt_u (local.get $reg) (i32.const 15))
      (then
        return
      )
    )
    (local.set $val
      (i32.and
        (local.get $val)
        (i32.load 
          (i32.add 
            (&psg.regmsk;)
            (i32.shl 
              (local.get $reg)
              (@psg.regmsk;)
            )
          )
        )
      ) 
    )

    (i32.store
      (i32.add 
        (&psg.reg;)
        (i32.shl 
          (local.get $reg)
          (@psg.reg;)
        )
      )
      (local.get $val)
    )
    
    (block $default
      (br_if $default (i32.gt_u (local.get $reg) (i32.const 13))) 
      (block $reg0_5
        (block $reg6
          (block $reg7
            (block $reg8_10
              (block $reg11_12
                (block $reg13
                  (br_table 
                    $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg6 $reg7 
                    $reg8_10 $reg8_10 $reg8_10 $reg11_12 $reg11_12 $reg13
                    (local.get $reg)
                  )
                )
                ;; reg 13
                (i32.store
                  (&psg.env_continue;) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 3))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (&psg.env_attack;) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 2))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (&psg.env_alternate;) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 1))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (&psg.env_hold;) 
                  (i32.and
                    (local.get $val)
                    (i32.const 1)
                  )
                )
                (i32.store
                  (&psg.env_face;) 
                  (i32.load (&psg.env_attack;)) 
                )
                (i32.store
                  (&psg.env_pause;) 
                  (i32.const 0) 
                )
                (i32.store
                  (&psg.env_count;) 
                  (i32.sub 
                    (i32.const 0x10000)
                    (i32.load (&psg.env_freq;))
                  )
                )
                (i32.store
                  (&psg.env_ptr;)
                  (select
                    (i32.const 0)
                    (i32.const 0x1f)
                    (i32.load (&psg.env_face;))
                  )
                )
                return
              )
              ;; reg11-12
              (i32.store
                (&psg.env_freq;)
                (i32.add 
                  (i32.shl
                    (i32.load (&psg.reg[12];))
                    (i32.const 8)
                  )
                  (i32.load(&psg.reg[11];))
                )
              )
              return
            )
            ;; reg 8-10
            (i32.store
              (i32.add 
                (&psg.volume;)
                (i32.shl 
                  (i32.sub (local.get $reg) (i32.const 8)) 
                  (@psg.volume;)
                )
              )
              (i32.shl
                (local.get $val)
                (i32.const 1)
              )
            )
            return
          )
          ;; reg 7
          ;;(local.set $val (i32.xor (i32.const 0xff) (local.get $val)))
          (i32.store (&psg.tmask[0];) (i32.and (local.get $val) (i32.const 1)))
          (i32.store (&psg.tmask[1];) (i32.and (local.get $val) (i32.const 2)))
          (i32.store (&psg.tmask[2];) (i32.and (local.get $val) (i32.const 4)))

          (i32.store (&psg.nmask[0];) (i32.and (local.get $val) (i32.const 8)))
          (i32.store (&psg.nmask[1];) (i32.and (local.get $val) (i32.const 16)))
          (i32.store (&psg.nmask[2];) (i32.and (local.get $val) (i32.const 32)))

          return
        )
        ;; reg 6
        (i32.store 
          (&psg.noise_freq;)
          (i32.shl
            (i32.and
              (local.get $val)
              (i32.const 31)
            )
            (i32.const 1)
          )
        )
        return
      ) 
      ;; reg 0-5
      (local.set $c 
        (i32.shr_u
          (local.get $reg)
          (i32.const 1)
        )
      )

      (i32.store
        (i32.add
          (&psg.freq;)
          (i32.shl (local.get $c) (@psg.freq;))
        )
        (i32.add
          (i32.shl 
            (i32.and 
              (i32.load
                (i32.add 
                  (&psg.reg;)
                  (i32.shl
                    (i32.add
                      (i32.shl
                        (local.get $c)
                        (i32.const 1)
                      )
                      (i32.const 1)
                    )
                    (@psg.reg;)
                  )
                )
              )
              (i32.const 15)
            )
            (i32.const 8)
          )
          (i32.load
            (i32.add
              (&psg.reg;)
              (i32.shl
                (i32.shl 
                  (local.get $c)
                  (i32.const 1)
                )
                (@psg.reg;)
              )
            )
          )
        )
      )
      return
    )
  )
)
```
