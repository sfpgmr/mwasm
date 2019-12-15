(module
  (memory $memory 1 )
  (data (i32.const 0) "\0a\00\00\00")(data (i32.const 4) "\00\00\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\00\00\05\00\00\00\06\00\00\00\07\00\00\00\08\00\00\00\09\00\00\00")
  (export "memory" (memory $memory))
  (export "memoryAdd" (func $memoryAdd))
  (func $memoryAdd (param $yy_index i32) (result i32)
    (i32.add
      (i32.load (i32.const 0 (; XX ;)))
      (i32.load 
        (i32.add
          (i32.const 4 (; YY ;))
          (i32.shl
            (local.get $yy_index)
            (i32.const 2 (; YY ;)) ;; @(メモリラベル);でメモリラベルの型サイズのlog2を埋め込む
          )
        )
      )
    )
  )
)
