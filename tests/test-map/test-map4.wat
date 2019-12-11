(module
(memory 0)
(data (i32.const 0) "\0a\00\00\00")(data (i32.const 0) "\00\00\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\00\00\05\00\00\00\06\00\00\00\07\00\00\00\08\00\00\00\09\00\00\00")
(export "test" (func $test))
(func $test (result i32)
  (i32.add
    (i32.load (i32.const 16 (; label2 ;)))
    (i32.load (i32.const 0 (; label1 ;)))
  )
)
)
