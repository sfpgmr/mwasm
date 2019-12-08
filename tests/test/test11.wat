(module
  (memory $memory 1 )
  (data (i32.const 0) "\41\20\00\00")(data (i32.const 4) "\db\0f\49\40")(data (i32.const 8) "\00\00\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\00\00\05\00\00\00\06\00\00\00\07\00\00\00\08\00\00\00\09\00\00\00")
  (export "memory" (memory $memory))
  (export "memoryAdd" (func $memoryAdd))
  (func $memoryAdd (result f32)
    (f32.add
      (f32.load (i32.const 0 (; XX ;)))
      (f32.load (i32.const 4 (; YY ;)))
    )
  )
)
