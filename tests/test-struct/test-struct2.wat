


(module
(memory 0)

(export "test" (func $test))
(func $test (result f32)
  (f32.add 
    (f32.load (i32.const 4 (; a.b ;)))
    (f32.load (i32.const 8 (; a.c ;)))
  )
)
)
