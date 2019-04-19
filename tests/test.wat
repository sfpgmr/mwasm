{
this.X = 0x1;
this.Y = 2;
this.Z = 0x3;
}

(module
  (export "test" (func $test))
  (memory $memory 1)
  (export "memory" (memory $memory))
  
  (func $test (result i32)
    i32.const {this.X}
    i32.const {this.Y}
    i32.add
  )
)