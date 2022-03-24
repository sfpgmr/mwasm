(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  (export "test" (func $test))
    (func $test (result f32)
      f32.const (; Math.cos(Math.PI / 4)  ;)0.7071067811865476
    )
)
