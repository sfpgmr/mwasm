





(; // ローカル変数の定義
$.X = 1;
 ;)


(module
(memory 0)
(export "test" (func $test))
(func $test (result i32)
  (i32.add 
    (i32.load (i32.const 8 (; c.b.a.a ;)))
    (i32.const 0 (; c.c ;))
  )
)
)
