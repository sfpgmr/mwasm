(; $.attributes = $attributes;

 ;)
(module
  (memory $memory 1 )
  
  (export "memory" (memory $memory))
  (export "memoryAdd" (func $memoryAdd))
  (func $memoryAdd
    (i32.store 
      (i32.const 16 (; AA ;))
      (i32.add
        (i32.load (i32.const 0 (; XX ;)))
        (i32.load (i32.const 4 (; YY ;)))
      )
    )
  )
)
