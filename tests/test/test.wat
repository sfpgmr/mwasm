(; $.X = 0x1;
$.Y = 2;
$.Z = 0x3;
 ;)

(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  ;; code
(export "test2" (func $test2))
(func $test2 (result i32)
  i32.const 2
)
;; code
(export "test3" (func $test2))
(func $test3 (result i32)
  i32.const 1 (; X ;)
  i32.const (; $.X + $.Y;  ;)3
  i32.add
)

  
    (export "testa" (func $testa))
    (func $testa (result i32)
      i32.const (; $.X ;)1
      i32.const (; $.X + $.Y  ;)3
      i32.add
    )
  
)
