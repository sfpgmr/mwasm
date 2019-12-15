

(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (i32.add 
    (i32.const 4 (; A.b ;))
    (i32.const 8 (; A ;))
  )
)
)
