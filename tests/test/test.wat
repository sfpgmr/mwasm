(; $.X = 0x1;
$.Y = 2;
$.Z = 0x3;
 ;)

(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  ;; {@include './test_inc.mwat'}
  
    (export "testa" (func $testa))
    (func $testa (result i32)
      i32.const (; $.X ;)1
      i32.const (; $.X + $.Y  ;)3
      i32.add
    )
  
)
