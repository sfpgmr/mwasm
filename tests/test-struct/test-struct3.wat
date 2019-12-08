


(module
(memory 0)

(export "test" (func $test))
(func $test (result f32)
  (f32.add 
    (f32.load (i32.const 0 (; a.a ;)))
    (f32.load (i32.const 4 (; a.a ;)))
  )
)
)
