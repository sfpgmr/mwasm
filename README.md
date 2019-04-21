# mwasm

## 概要

mwasm用のプリプロセッサです。定数式はJavaScriptの構文を採用し、アセンブラでいうところのマクロ機能の一部を実現します。

```
{@
$.X = 0x1;
$.Y = 2;
$.Z = 0x3;
}

(module
  (memory $memory 1)
  (export "memory" (memory $memory))
  {@include './test_inc.mwat'}
{@if $.X < 1}
  (export "test" (func $test))
  (func $test (result i32)
    i32.const @X;; comment
    i32.const {$ $.X + $.Y }
    {@if $.Y}
    i32.add
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
    {@endif}
  )
{@else}
  (export "testa" (func $testa))
  (func $testa (result i32)
    i32.const @X;; comment
    i32.const {$ $.X + $.Y }
    i32.add
  )
{@endif}
)
```

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

作成中の状態です。wsl上でのみ実行できることを確認しています。

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

### {$ JS式}

JS式を実行し、結果をその位置に埋め込みます。

### @プロパティ名

コンテキストオブジェクト`$`のプロパティ値を埋め込みます。

### {@include JS式}

JS式の結果得られるpathにあるファイルをインクルードします。

### {@if JS式}　ソース１ [{@else} ソース２] {@endif}

JS式が真の場合ソース1を埋め込み、そうでない場合はソース2を埋め込みます。
`@else ソース2`は省略可能です。

