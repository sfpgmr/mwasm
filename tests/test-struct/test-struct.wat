








(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (i32.add 
    (i32.load (i32.const 8))
    (i32.const 0)
  )
)
)
