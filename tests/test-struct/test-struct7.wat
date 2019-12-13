

(module
(memory 0)
(data (i32.const 0) "[object Object],[object Object],[object Object]")
(export "test" (func $test))
(func $test (result i32)
    (i32.const 4 (; A.b ;))
)
)
