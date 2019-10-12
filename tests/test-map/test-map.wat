(; $.INDEX = 10;
 ;)



(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (i32.add
    (i32.const 50 (; label + INDEX ;))
    (i32.const 20 (; INDEX + 10 ;))
  )
)
)
