   (module (memory $memory 1  ) (export "memory" (memory $memory)) (export "test" (func $test)) (func $test (result i32) (i32.load (i32.const 564)) i32.const 1 i32.add ) ) 