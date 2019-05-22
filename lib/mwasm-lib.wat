(module
  (export "i32tof32" (func $i32tof32))
  (export "i64tof64" (func $i64tof64))
  (export "i64Neg" (func $i64Neg))
  (export "uint8ArrayToi64" (func $uint8ArrayToi64))
  (export "decimalArrayToi64" (func $decimalArrayToi64))
  (export "binaryArrayToi64" (func $binaryArrayToi64))
  (export "octalArrayToi64" (func $octalArrayToi64))
  (export "hexArrayToi64" (func $hexArrayTou64))
  (export "decimalArrayTou64" (func $decimalArrayTou64))
  (export "binaryArrayTou64" (func $binaryArrayTou64))
  (export "octalArrayTou64" (func $octalArrayTou64))
  (export "hexArrayTou64" (func $hexArrayTou64))
  (memory $memory 1)
  (export "memory" (memory $memory))
  
  ;; IEE754 float32のビットパターンを持つ32ビット整数値をf32に変換する
  (func $i32tof32 (param $i i32) (param $minus i32) (result f32)
    (f32.reinterpret_i32
      (i32.xor
          (local.get $i)
          (local.get $minus)
      )
    )
  )

  ;; IEEE754 float64のビットパターンを持つ2つの32ビット値（high,low）を元にして、64bit floatを返す
  (func $i64tof64 (param $low i32) (param $high i32) (param $minus i32) (result f64)
    (f64.reinterpret_i64
      (i64.xor
        (i64.or
          (i64.shl 
            (i64.extend_i32_u (local.get $high))
            (i64.const 32) 
          )
          (i64.extend_i32_u (local.get $low))
        )
        (i64.shl
          (i64.extend_i32_u (local.get $minus))
          (i64.const 32)
        )
      )
    )
  )

  ;; 整数値の2の補数をとる
  (func $i64Neg (param $low i32) (param $high i32)
    (i64.store
      (i32.const 0)
      (i64.add
        (i64.xor
          (i64.or 
            (i64.extend_i32_u (local.get $low))
            (i64.shl 
              (i64.extend_i32_u (local.get $high))
              (i64.const 32) 
            )
          )
          (i64.const 0xffffffffffffffff)
        )
        (i64.const 1)
      )
    )
  )


  ;; utf16 10進整数文字配列からi64値に変換
  (func $decimalArrayToi64 
    ;; 数字列はリニアメモリの先頭に格納
    ;; 文字数
    (param $length i32) 
    ;; 返還後の数値をどのメモリに保存するか
    (param $outoffset i32)
    ;; 符号 正 ... 0 負 ... それ以外
    (param $sign i32)
    ;; 戻り値 正常終了 ... 0 エラー ... 0以外
    (result i32) 
    ;;ローカル変数
    (local $offset i32)
    (local $l i32)
    (local $temp i64)

    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (i64.mul (local.get $temp) (i64.const 10))
        (if (result i64)
          (i32.and 
            (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x30))
            (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x39))
          )
          (then
            (i64.sub(i64.load16_u (local.get $offset)) (i64.const 0x30))
          )
          (else
            ;; 0x30-0x39 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (i64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (if
      (i32.eqz (local.get $sign))
      (then
        ;; ＋の場合
        (i64.store (local.get $outoffset) (local.get $temp))
      )
      (else
        ;; -の場合
        (i64.store (local.get $outoffset) (i64.sub (i64.const 0) (local.get $temp)))
      )
    )
    (i32.const 0)
  )

  ;; utf16 2進整数文字配列からi64値に変換
  (func $binaryArrayToi64 
    ;; 数字列はリニアメモリの先頭に格納
    ;; 文字数
    (param $length i32) 
    ;; 返還後の数値をどのメモリに保存するか
    (param $outoffset i32)
    ;; 符号 正 ... 0 負 ... それ以外
    (param $sign i32)
    ;; 戻り値 正常終了 ... 0 エラー ... 0以外
    (result i32) 
    ;;ローカル変数
    (local $offset i32)
    (local $l i32)
    (local $temp i64)

    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (i64.shl (local.get $temp) (i64.const 1));; *2
        (if (result i64)
          (i32.and 
            (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x30))
            (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x31))
          )
          (then
            (i64.sub(i64.load16_u (local.get $offset)) (i64.const 0x30))
          )
          (else
            ;; 0x30-0x31 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (i64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (if
      (i32.eqz (local.get $sign))
      (then
        ;; ＋の場合
        (i64.store (local.get $outoffset) (local.get $temp))
      )
      (else
        ;; -の場合
        (i64.store (local.get $outoffset) (i64.sub (i64.const 0) (local.get $temp)))
      )
    )
    (i32.const 0)
  )
   ;; utf-16 8進整数文字配列からi64値に変換する
  (func $octalArrayToi64 (param $length i32) (param $outoffset i32) (param $sign i32) (result i32) (local $offset i32) (local $l i32) (local $temp i64)
    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (i64.shl (local.get $temp) (i64.const 3));; *8
        (if (result i64)
          (i32.and 
            (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x30))
            (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x37))
          )
          (then
            (i64.sub(i64.load16_u (local.get $offset)) (i64.const 0x30))
          )
          (else
            ;; 0x30-0x31 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (i64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (if
      (i32.eqz (local.get $sign))
      (then
        ;; ＋の場合
        (i64.store (local.get $outoffset) (local.get $temp))
      )
      (else
        ;; -の場合
        (i64.store (local.get $outoffset) (i64.sub (i64.const 0) (local.get $temp)))
      )
    )
    (i32.const 0)
  )
 
  ;; utf-16 16進整数文字配列からi64値に変換する
  (func $hexArrayToi64 
    (param $length i32)(param $outoffset i32)(param $sign i32)
    (result i32) 
    (local $offset i32) (local $l i32) (local $temp i64)
    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (i64.shl (local.get $temp) (i64.const 4)) ;; shift 4bit (=x16)
        (if (result i64) 
          ;; 0-9(0x30-0x39)
          (i32.and 
            (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x30))
            (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x39))
          )
          (then
            (i64.sub(i64.load16_u (local.get $offset)) (i64.const 0x30))
          )
          (else
           (if (result i64)
            ;; A-F (0x41-0x46)
            (i32.and 
              (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x41))
              (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x46))
            )
            (then
              (i64.sub(i64.load16_u (local.get $offset)) (i64.const 35))
            )
            (else 
              (if (result i64)
                ;; a-f (0x61-0x66)
                (i32.and
                  (i64.ge_u (i64.load16_u (local.get $offset)) (i64.const 0x61))
                  (i64.le_u (i64.load16_u (local.get $offset)) (i64.const 0x66))
                )
                (then
                  (i64.sub(i64.load16_u (local.get $offset)) (i64.const 87))
                )
                (else
                  ;; 16進数文字以外が含まれている場合エラーを返して終了。
                  i32.const 1
                  return
                )
              )
            )
           )
          )
        ) 
        (i64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (if 
      (i32.eqz (local.get $sign))
      (then
        ;; ＋の場合
        (i64.store (local.get $outoffset) (local.get $temp))
      )
      (else
        ;; -の場合
        (i64.store (local.get $outoffset) (i64.sub (i64.const 0) (local.get $temp)))
      )
    )   
    (i32.const 0)
  )


  ;; utf-16 10進整数文字配列からu64値に変換する
  (func $decimalArrayTou64 (param $length i32) (param $outoffset i32) (param $sign i32) (result i32) (local $offset i32) (local $l i32) (local $temp u64)
    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (u64.mul (local.get $temp) (u64.const 10))
        (if (result u64)
          (i32.and 
            (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x30))
            (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x39))
          )
          (then
            (u64.sub(u64.load16_u (local.get $offset)) (u64.const 0x30))
          )
          (else
            ;; 0x30-0x39 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (u64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (u64.store (local.get $outoffset) (local.get $temp))
    (i32.const 0)
  )

  ;; utf-16 2進整数文字配列からu64値に変換する
  (func $binaryArrayTou64 (param $length i32) (param $outoffset i32) (param $sign i32) (result i32) (local $offset i32) (local $l i32) (local $temp u64)
    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (u64.shl (local.get $temp) (u64.const 1));; *2
        (if (result u64)
          (i32.and 
            (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x30))
            (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x31))
          )
          (then
            (u64.sub(u64.load16_u (local.get $offset)) (u64.const 0x30))
          )
          (else
            ;; 0x30-0x31 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (u64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (u64.store (local.get $outoffset) (local.get $temp))
    (i32.const 0)
  )
  
  ;; utf-16 8進整数文字配列からu64値に変換する
  (func $octalArrayTou64 (param $length i32) (param $outoffset i32) (param $sign i32) (result i32) (local $offset i32) (local $l i32) (local $temp u64)
    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (u64.shl (local.get $temp) (u64.const 3));; *8
        (if (result u64)
          (i32.and 
            (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x30))
            (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x37))
          )
          (then
            (u64.sub(u64.load16_u (local.get $offset)) (u64.const 0x30))
          )
          (else
            ;; 0x30-0x31 以外の文字列が含まれている場合はエラーで終了
            (i32.const 1)
            return
          )
        )
        (u64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (u64.store (local.get $outoffset) (local.get $temp))
    (i32.const 0)
  )
 
  ;; utf-16 16進整数文字配列からu64値に変換する
  (func $hexArrayTou64 
    (param $length i32)(param $outoffset i32)
    (result i32) 
    (local $offset i32) (local $l i32) (local $temp u64)

    (local.set $l (i32.shl (local.get $length) (i32.const 1)))  
    (block $exit 
      (loop $loop
        (br_if $exit (i32.le_u (local.get $l) (local.get $offset)))
        (u64.shl (local.get $temp) (u64.const 4)) ;; shift 4bit (=x16)
        (if (result u64) 
          ;; 0-9(0x30-0x39)
          (i32.and 
            (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x30))
            (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x39))
          )
          (then
            (u64.sub(u64.load16_u (local.get $offset)) (u64.const 0x30))
          )
          (else
           (if (result u64)
            ;; A-F (0x41-0x46)
            (i32.and 
              (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x41))
              (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x46))
            )
            (then
              (u64.sub(u64.load16_u (local.get $offset)) (u64.const 35))
            )
            (else 
              (if (result u64)
                ;; a-f (0x61-0x66)
                (i32.and
                  (u64.ge_u (u64.load16_u (local.get $offset)) (u64.const 0x61))
                  (u64.le_u (u64.load16_u (local.get $offset)) (u64.const 0x66))
                )
                (then
                  (u64.sub(u64.load16_u (local.get $offset)) (u64.const 87))
                )
                (else
                  ;; 16進数文字以外が含まれている場合エラーを返して終了。
                  i32.const 1
                  return
                )
              )
            )
           )
          )
        ) 
        (u64.add)
        (local.set $temp)
        (local.set $offset (i32.add (local.get $offset) (i32.const 2)))
        (br $loop)
      )
    )
    (u64.store (local.get $outoffset) (local.get $temp))
    (i32.const 0)
  )
)
