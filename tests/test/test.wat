  (module (memory $memory 1) (export "memory" (memory $memory)) (export "test2" (func $test2)) (func $test2 (result i32) i32.const 1 i32.const 3 i32.add 
i32.const 4
i32.add
i32.const 5
i32.add
i32.const 6
i32.add
i32.const 7
i32.add ) (export "test3" (func $test2)) (func $test3 (result i32) i32.const 5 i32.const 7 i32.add 
i32.const 8
i32.add
i32.const 9
i32.add
i32.const 10
i32.add
i32.const 11
i32.add )    (export "testa" (func $testa)) (func $testa (result i32) i32.const 9 i32.const 11 i32.add )  ) 