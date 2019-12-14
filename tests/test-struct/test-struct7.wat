

(module
(memory 0)
(data (i32.const 0) "\01\00\00\00\02\00\00\00")(data (i32.const 12) "\03\00\00\00\04\00\00\00")(data (i32.const 24) "\05\00\00\00\06\00\00\00")
(export "test" (func $test))
(func $test (result i32)
    (i32.const 4 (; A.b ;))
)
)
